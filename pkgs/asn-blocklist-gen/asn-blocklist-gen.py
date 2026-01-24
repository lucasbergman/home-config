#!/usr/bin/env python3
import argparse
import json
import logging
import sys
from collections import defaultdict
from typing import NamedTuple, TextIO


class _BGPRoute(NamedTuple):
    """A BGP route mapping a CIDR to an ASN."""

    cidr: str
    asn: int


def _load_bgp_table(path: str) -> dict[int, list[_BGPRoute]]:
    """Load the BGP routing table."""
    logging.info(f"Loading BGP table from {path}...")
    result: dict[int, list[_BGPRoute]] = defaultdict(list)
    nroutes = 0
    with open(path, "r") as f:
        for line in f:
            rec = json.loads(line)
            route = _BGPRoute(cidr=rec["CIDR"], asn=int(rec["ASN"]))
            result[route.asn].append(route)
            nroutes += 1
    logging.info(f"Loaded {nroutes} BGP routes")
    return result


def _parse_target_asns(stream: TextIO) -> set[int]:
    """Parse target ASNs from input stream."""
    targets: set[int] = set()
    for line in stream:
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        # Handle "AS1234" or "1234"
        asn_str = line.upper()
        if asn_str.startswith("AS"):
            asn_str = asn_str[2:]

        try:
            targets.add(int(asn_str))
        except ValueError:
            logging.warning(f"Skipping invalid ASN: {line}")
            continue
    return targets


def main() -> None:
    logging.basicConfig(level=logging.INFO, stream=sys.stderr)
    parser = argparse.ArgumentParser(
        description="Generate nftables blocklist from ASN list."
    )
    parser.add_argument(
        "files",
        metavar="FILE",
        nargs="*",
        help="Input files with ASNs (default: stdin)",
    )
    parser.add_argument(
        "--bgp-table",
        default="/var/lib/bgp-data/table.jsonl",
        help="Path to BGP table JSONL file",
    )
    parser.add_argument(
        "--set-name",
        default="blocked_asns",
        help="Name of the nftables set",
    )
    parser.add_argument(
        "--table",
        default="filter",
        help="Name of the nftables table (default: filter)",
    )
    parser.add_argument(
        "--family",
        default="inet",
        help="Address family (default: inet)",
    )
    args = parser.parse_args()

    block_asns: set[int] = set()
    if not args.files:
        block_asns.update(_parse_target_asns(sys.stdin))
    else:
        for fname in args.files:
            with open(fname, "r") as f:
                block_asns.update(_parse_target_asns(f))

    if not block_asns:
        logging.warning("No ASNs provided. Exiting.")
        return

    routes = _load_bgp_table(args.bgp_table)
    blocked_cidrs = [r.cidr for a in block_asns for r in routes[a]]
    if not blocked_cidrs:
        logging.warning("No CIDRs found for the specified ASNs")
        return
    logging.info(f"Found {len(blocked_cidrs)} CIDRs to block")

    print(f"flush set {args.family} {args.table} {args.set_name}")
    for cidr in sorted(set(blocked_cidrs)):
        print(f"add element {args.family} {args.table} {args.set_name} {{ {cidr} }}")


if __name__ == "__main__":
    main()
