"""Read Gmail labels from X-Gmail-Labels headers and output notmuch tag commands.

When you export your Gmail corpus using Google Takeout, each message has a header field
X-Gmail-Labels with a comma-separated list of labels. This script extracts the
Message-ID and X-Gmail-Labels from each message and prints a line in the format
expected by 'notmuch tag --batch'. Note that Gmail bulk exports are mbox files, so you
have to convert that to Maildir first.

Usage:
    notmuch_read_gmail_labels.py MAILDIR | notmuch tag --batch
"""

import sys
import urllib.parse
from email import policy
from email.headerregistry import BaseHeader
from email.parser import BytesHeaderParser
from pathlib import Path


def _format_tag(tag: str) -> str:
    """Hex-encode tags for notmuch batch-tag format."""
    return urllib.parse.quote(tag.strip(), safe="")


def process_maildir(maildir_path: str | Path) -> None:
    cur_path = Path(maildir_path) / "cur"
    if not cur_path.is_dir():
        print(f"Error: {cur_path} is not a directory", file=sys.stderr)
        sys.exit(1)

    parser = BytesHeaderParser(policy=policy.default)
    count = 0

    for file_path in cur_path.iterdir():
        if not file_path.is_file():
            continue

        count += 1
        if count % 5000 == 0:
            print(f"# Processed {count} messages...", file=sys.stderr)

        with open(file_path, "rb") as f:
            msg = parser.parse(f)

        msg_id: BaseHeader | None = msg.get("Message-ID")
        if not msg_id:
            print(f"# Message has no Message-ID: {file_path}", file=sys.stderr)
            continue

        labels: BaseHeader | None = msg.get("X-Gmail-Labels")
        if not labels:
            continue  # Not from Gmail
        labels_list = sorted({l.strip() for l in str(labels).split(",") if l.strip()})
        if not labels_list:
            print(f"# Bogus Gmail labels header field: {file_path}", file=sys.stderr)
            continue

        # Batch format: +tag1 +tag%20with%20space -- id:msgid
        tag_str = " ".join(f"+{_format_tag(t)}" for t in labels_list)
        clean_id = str(msg_id).strip().strip("<>")
        print(f"{tag_str} -- id:{clean_id}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: notmuch_read_gmail_labels.py MAILDIR")
        sys.exit(1)
    process_maildir(sys.argv[1])
