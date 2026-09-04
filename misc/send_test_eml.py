#!/usr/bin/env python3
import argparse
import email
import email.policy
import socket
import sys
from email.utils import parseaddr


def main():
    parser = argparse.ArgumentParser(
        description="Inject an .eml message into Postfix over SMTP using XCLIENT for testing."
    )
    parser.add_argument("eml_file", help="Path to the .eml file to send")
    parser.add_argument(
        "--host", default="127.0.0.1", help="SMTP server host (default: 127.0.0.1)"
    )
    parser.add_argument(
        "--port", type=int, default=25, help="SMTP server port (default: 25)"
    )
    parser.add_argument(
        "--rcpt",
        default="lucas@bergman.house",
        help="Recipient address (default: lucas@bergman.house)",
    )
    parser.add_argument(
        "--mail-from",
        default=None,
        help="Envelope sender (default: extracted from Return-Path/From)",
    )
    parser.add_argument(
        "--client-ip",
        required=True,
        help="Simulated client IP for XCLIENT",
    )
    parser.add_argument(
        "--client-name",
        required=True,
        help="Simulated client hostname for XCLIENT",
    )
    parser.add_argument(
        "--no-hold", action="store_true", help="Do not inject X-Queue-Hold header"
    )

    args = parser.parse_args()

    with open(args.eml_file, "rb") as f:
        msg_bytes = f.read()

    msg = email.message_from_bytes(msg_bytes, policy=email.policy.default)
    mail_from = args.mail_from
    if not mail_from:
        if msg.get("Return-Path"):
            mail_from = str(msg.get("Return-Path")).strip("<> ")
        elif msg.get("From"):
            mail_from = parseaddr(msg.get("From"))[1]
        if not mail_from:
            sys.exit(
                "Error: Could not determine sender from Return-Path or From header. Specify with --mail-from."
            )

    inject_hold_header = not args.no_hold and not msg.get("X-Queue-Hold")

    print(f"Connecting to {args.host}:{args.port}...")
    s = socket.create_connection((args.host, args.port))

    def send_cmd(cmd):
        print(f"> {cmd}")
        s.sendall((cmd + "\r\n").encode("utf-8"))
        resp = s.recv(4096).decode("utf-8", errors="replace")
        print(resp.strip())
        return resp

    # 220 greeting
    greeting = s.recv(4096).decode("utf-8", errors="replace").strip()
    print(greeting)

    # Handshake & XCLIENT
    send_cmd("EHLO localhost")
    send_cmd(f"XCLIENT ADDR={args.client_ip} NAME={args.client_name}")
    send_cmd("EHLO mail.example.com")
    send_cmd(f"MAIL FROM:<{mail_from}>")
    send_cmd(f"RCPT TO:<{args.rcpt}>")
    send_cmd("DATA")

    # Format message with CRLF line endings and dot-stuffing
    text = msg_bytes.decode("utf-8", errors="replace")
    lines = text.splitlines()
    stuffed_lines = []
    for line in lines:
        if line.startswith("."):
            stuffed_lines.append("." + line)
        else:
            stuffed_lines.append(line)
    if inject_hold_header:
        stuffed_lines.insert(0, "X-Queue-Hold: yes")
    payload = "\r\n".join(stuffed_lines) + "\r\n.\r\n"

    print(f"> [Sending {len(stuffed_lines)} lines from {args.eml_file}]")
    s.sendall(payload.encode("utf-8"))

    # Result (Queued as ...)
    res = s.recv(4096).decode("utf-8", errors="replace").strip()
    print(res)

    send_cmd("QUIT")
    s.close()


if __name__ == "__main__":
    main()
