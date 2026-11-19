import argparse
import json
import os
import subprocess
import sys
import tempfile
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, NamedTuple


class RuleKey(NamedTuple):
    family: str
    table: str
    chain: str
    rule: str


@dataclass
class DropCounts:
    packets: int = 0
    bytes: int = 0


def escape_label(val: str) -> str:
    """Escape a Prometheus label value per the text exposition format."""
    return val.replace("\\", "\\\\").replace("\n", "\\n").replace('"', '\\"')


def format_labels(key: RuleKey) -> str:
    return (
        f'family="{escape_label(key.family)}",'
        f'table="{escape_label(key.table)}",'
        f'chain="{escape_label(key.chain)}",'
        f'rule="{escape_label(key.rule)}"'
    )


def extract_drop_counts(ruleset: dict[str, Any]) -> dict[RuleKey, DropCounts]:
    """Extract packet and byte counters for nftables drop/reject rules.

    Rules sharing the same (family, table, chain, comment) tuple—including
    uncommented rules—are summed so Prometheus label sets stay unique.
    """
    counts: dict[RuleKey, DropCounts] = defaultdict(DropCounts)

    for item in ruleset.get("nftables", []):
        rule = item.get("rule")
        if not isinstance(rule, dict):
            continue

        counter: dict[str, Any] | None = None
        is_drop = False
        for stmt in rule.get("expr", []):
            if not isinstance(stmt, dict):
                continue
            # Ignore named counter references (str) to avoid double-counting.
            if isinstance(stmt.get("counter"), dict):
                counter = stmt["counter"]
            if "drop" in stmt or "reject" in stmt:
                is_drop = True

        if counter is not None and is_drop:
            key = RuleKey(
                family=rule.get("family", ""),
                table=rule.get("table", ""),
                chain=rule.get("chain", ""),
                rule=rule.get("comment", ""),
            )
            counts[key].packets += int(counter.get("packets", 0))
            counts[key].bytes += int(counter.get("bytes", 0))

    return counts


def render_metrics(counts: dict[RuleKey, DropCounts]) -> str:
    """Render drop counts in Prometheus text exposition format."""
    sorted_items = sorted(counts.items())
    metrics = [
        (
            "firewall_blocked_packets_total",
            "Total packets dropped or rejected by nftables",
            "packets",
        ),
        (
            "firewall_blocked_bytes_total",
            "Total bytes dropped or rejected by nftables",
            "bytes",
        ),
    ]

    lines: list[str] = []
    for name, help_text, field in metrics:
        lines.append(f"# HELP {name} {help_text}")
        lines.append(f"# TYPE {name} counter")
        for key, drop_counts in sorted_items:
            value = getattr(drop_counts, field)
            lines.append(f"{name}{{{format_labels(key)}}} {value}")

    return "\n".join(lines) + "\n"


def write_atomic(path: Path, content: str) -> None:
    """Atomically write content to path with 0644 permissions."""
    tmp_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=path.parent,
            prefix=f".{path.name}.",
            suffix=".tmp",
            delete=False,
        ) as f:
            tmp_path = Path(f.name)
            f.write(content)
        os.chmod(tmp_path, 0o644)
        os.replace(tmp_path, path)
    except Exception:
        if tmp_path is not None:
            tmp_path.unlink(missing_ok=True)
        raise


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(
        description="Export nftables drop/reject counters as Prometheus metrics."
    )
    parser.add_argument(
        "output",
        nargs="?",
        type=Path,
        help="Path to write .prom file atomically (defaults to stdout).",
    )
    args = parser.parse_args(argv)

    # --terse omits set elements (which can be huge for BGP blocklists) while
    # preserving rule counters.
    raw = subprocess.check_output(
        ["nft", "--json", "--terse", "list", "ruleset"],
        text=True,
    )
    counts = extract_drop_counts(json.loads(raw))
    metrics = render_metrics(counts)

    if args.output is not None:
        write_atomic(args.output, metrics)
    else:
        sys.stdout.write(metrics)


if __name__ == "__main__":
    main()
