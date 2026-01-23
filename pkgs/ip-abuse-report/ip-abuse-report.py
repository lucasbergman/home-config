#!/usr/bin/env python3
import argparse
import csv
import json
import logging
import sys
from collections import defaultdict, namedtuple
from typing import Dict, TextIO

import pytricia  # type: ignore


class _ASNData(namedtuple("_ASNData", ["asn", "name", "cc"])):
    """Metadata for an Autonomous System."""

    pass


class _ASNStats(object):
    """Aggregated abuse statistics for a single ASN."""

    @staticmethod
    def new() -> "_ASNStats":
        return _ASNStats()

    def __init__(self) -> None:
        self.asn_id: int = 0
        self.attempts: defaultdict[str, int] = defaultdict(int)

    def add_attempts(self, ip: str, attempts: int) -> None:
        """Record a number of abuse attempts from a specific IP address."""
        self.attempts[ip] = self.attempts[ip] + attempts

    def naddrs(self) -> int:
        """Return the number of unique IP addresses recorded for this ASN."""
        return len(self.attempts)

    def nattempts(self) -> int:
        """Return the total number of abuse attempts across all IPs in this ASN."""
        return sum(self.attempts.values())


_MISSING_ASN = _ASNData(asn="UNKNOWN", name="Unknown Network", cc="??")


def _load_bgp_table(path: str, asn_meta: Dict[int, _ASNData]) -> pytricia.PyTricia:
    """Load the BGP routing table into a prefix trie, mapping CIDRs to ASN metadata."""
    logging.info(f"Loading BGP table from {path}...")
    result = pytricia.PyTricia()
    with open(path, "r") as f:
        for line in f:
            rec = json.loads(line)
            result[rec["CIDR"]] = asn_meta[int(rec["ASN"])]
    logging.info(f"Loaded {len(result)} BGP routes")
    return result


def _load_asn_metadata(path: str) -> Dict[int, _ASNData]:
    """Load ASN name and country metadata from a CSV file."""
    logging.info(f"Loading ASN metadata from {path}...")
    result: Dict[int, _ASNData] = defaultdict(lambda: _MISSING_ASN)
    with open(path, "r", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            asn_str: str = row["asn"]  # e.g. "AS123"
            asn_id: int = int(asn_str[2:])
            result[asn_id] = _ASNData(asn=asn_id, name=row["name"], cc=row["cc"])
    logging.info(f"Loaded {len(result)} ASN records")
    return result


def main() -> None:
    logging.basicConfig(level=logging.INFO, stream=sys.stderr)
    parser = argparse.ArgumentParser(
        description="Map IPs to ASNs and generate abuse report."
    )
    parser.add_argument(
        "files", metavar="FILE", nargs="*", help="Input files with IPs (default: stdin)"
    )
    parser.add_argument(
        "--bgp-table",
        default="/var/lib/bgp-data/table.jsonl",
        help="Path to BGP table JSONL file",
    )
    parser.add_argument(
        "--asn-table",
        default="/var/lib/bgp-data/asns.csv",
        help="Path to ASN metadata CSV file",
    )
    parser.add_argument(
        "--min-attempts",
        type=int,
        default=5,
        help="Minimum attempts required to report an ASN",
    )
    args = parser.parse_args()

    asn_meta = _load_asn_metadata(args.asn_table)
    bgp_ranges: pytricia.PyTricia = _load_bgp_table(args.bgp_table, asn_meta)

    attempts_per_addr: Dict[str, int] = defaultdict(int)

    def count_ips(stream: TextIO) -> None:
        for line in stream:
            ip: str = line.strip()
            if not ip:
                continue
            attempts_per_addr[ip] += 1

    if not args.files:
        count_ips(sys.stdin)
    else:
        for fname in args.files:
            with open(fname, "r") as f:
                count_ips(f)

    asn_stats: Dict[int, _ASNStats] = defaultdict(_ASNStats.new)

    for addr, attempts in attempts_per_addr.items():
        asn_data: _ASNData = bgp_ranges.get(addr, _MISSING_ASN)
        stats = asn_stats[asn_data.asn]
        stats.asn_id = asn_data.asn
        stats.add_attempts(addr, attempts)

    asn_stats_sorted = sorted(
        [s for s in asn_stats.values() if s.nattempts() >= args.min_attempts],
        key=_ASNStats.nattempts,
        reverse=True,
    )

    # Nothing to report
    if not asn_stats_sorted:
        return

    print(f"{'Attempts':<10} {'Addresses':<12} {'ASN':<10} {'CC':<4} {'Name'}")
    print("-" * 60)

    for stats in asn_stats_sorted:
        asn_info = asn_meta[stats.asn_id]
        print(
            f"{stats.nattempts():<10} "
            f"{stats.naddrs():<12} AS{stats.asn_id:<8} "
            f"{asn_info.cc:<4} {asn_info.name}"
        )


if __name__ == "__main__":
    main()
