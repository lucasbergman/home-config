#!/usr/bin/env python3
import argparse
import json
import logging
import sys
from collections import defaultdict, namedtuple


class _ASNData(namedtuple("_ASNData", ["asn", "name", "cc"])):
    """Metadata for an Autonomous System."""

    pass


class _ASNStats(object):
    """Aggregated abuse statistics for a single ASN."""

    @staticmethod
    def new() -> "_ASNStats":
        return _ASNStats()

    def __init__(self) -> None:
        self.asn_id: str = ""
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


def main() -> None:
    logging.basicConfig(level=logging.INFO, stream=sys.stderr)
    parser = argparse.ArgumentParser(
        description="Aggregate abuse attempts by ASN and generate report."
    )
    parser.add_argument(
        "--min-attempts",
        type=int,
        default=5,
        help="Minimum attempts required to report an ASN",
    )
    args = parser.parse_args()

    asn_stats: dict[str, _ASNStats] = defaultdict(_ASNStats.new)
    asn_meta: dict[str, _ASNData] = {}

    line_num = 0
    for line in sys.stdin:
        line_num += 1
        line = line.strip()
        if not line:
            continue

        record = json.loads(line)
        ip = record.get("ip", "").strip()
        if not ip:
            logging.warning(f"line {line_num}: no ip field")
            continue

        asn: str = record["asn"]
        asn_name = record["asn_name"]
        asn_cc = record["asn_country"]

        if asn not in asn_meta:
            asn_meta[asn] = _ASNData(asn=asn, name=asn_name, cc=asn_cc)

        stats = asn_stats[asn]
        stats.asn_id = asn
        stats.add_attempts(ip, 1)

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
