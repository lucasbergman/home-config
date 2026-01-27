#!/usr/bin/env python3
import argparse
import csv
import json
import logging
import sys
from collections import defaultdict, namedtuple

import pytricia  # type: ignore


class _ASNData(namedtuple("_ASNData", ["asn", "name", "cc"])):
    """Metadata for an Autonomous System."""

    pass


_MISSING_ASN = _ASNData(asn="UNKNOWN", name="Unknown Network", cc="??")


def _load_bgp_table(path: str, asn_meta: dict[int, _ASNData]) -> pytricia.PyTricia:
    """Load the BGP routing table into a prefix trie, mapping CIDRs to ASN metadata."""
    logging.info(f"Loading BGP table from {path}...")
    result = pytricia.PyTricia()
    with open(path, "r") as f:
        for line in f:
            rec = json.loads(line)
            result[rec["CIDR"]] = asn_meta[int(rec["ASN"])]
    logging.info(f"Loaded {len(result)} BGP routes")
    return result


def _load_asn_metadata(path: str) -> dict[int, _ASNData]:
    """Load ASN name and country metadata from a CSV file."""
    logging.info(f"Loading ASN metadata from {path}...")
    result: dict[int, _ASNData] = defaultdict(lambda: _MISSING_ASN)
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
        description="Annotate IP addresses with ASN information"
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
    args = parser.parse_args()

    asn_meta = _load_asn_metadata(args.asn_table)
    bgp_ranges: pytricia.PyTricia = _load_bgp_table(args.bgp_table, asn_meta)

    line_num = 0
    for line in sys.stdin:
        line_num += 1
        record = json.loads(line.strip())
        addr = record.get("ip", "").strip()
        if not addr:
            logging.warning(f"line {line_num}: no ip field")
            print(json.dumps(record))
            continue
        asn_data: _ASNData = bgp_ranges.get(addr, _MISSING_ASN)
        record["asn"] = str(asn_data.asn)
        record["asn_name"] = asn_data.name
        record["asn_country"] = asn_data.cc
        print(json.dumps(record))


if __name__ == "__main__":
    main()
