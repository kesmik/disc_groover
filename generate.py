
#!/usr/bin/env python3
"""Batch-export white and black STL files from disc_groover.scad."""

from __future__ import annotations

import argparse
import math
import os
from pathlib import Path
import shutil
import subprocess
import sys

SCAD_FILE = Path(__file__).resolve().with_name("disc_groover.scad")

# Only parameters that exist in the current SCAD file are accepted.
NUMERIC_PARAMETERS = {
    "white_t", "black_t", "fit_clearance", "disc_d",
    "main_hole_d", "lobe_d", "lock_span", "lobe_angle",
    "barcode_length", "edge_margin", "wide_width", "narrow_width",
    "wide_corner_radius", "narrow_corner_radius", "id_font_size",
    "id_y", "id_digit_spacing", "id_bridge",
}
BOOLEAN_PARAMETERS = {"show_id", "use_raised_inserts"}


def parse_ids(expression: str) -> list[int]:
    """Parse '1,2,22,990-994' into sorted, unique integer IDs."""
    result: set[int] = set()
    for item in expression.split(","):
        item = item.strip()
        if not item:
            raise ValueError("Empty item in --ids")
        if "-" in item:
            fields = item.split("-")
            if len(fields) != 2:
                raise ValueError(f"Invalid ID range: {item}")
            start, end = map(int, fields)
            if start > end:
                raise ValueError(f"Reversed range: {item}")
            if not 0 <= start <= end <= 1023:
                raise ValueError("IDs must be in the range 0..1023")
            result.update(range(start, end + 1))
        else:
            disc_id = int(item)
            if not 0 <= disc_id <= 1023:
                raise ValueError("IDs must be in the range 0..1023")
            result.add(disc_id)
    if not result:
        raise ValueError("No IDs specified")
    return sorted(result)


def build_overrides(entries: list[str]) -> list[str]:
    result: list[str] = []
    for entry in entries:
        name, sep, value = entry.partition("=")
        if not sep:
            raise ValueError(f"Expected NAME=VALUE: {entry}")
        name, value = name.strip(), value.strip()
        if name in NUMERIC_PARAMETERS:
            number = float(value)
            if not math.isfinite(number):
                raise ValueError(f"Non-finite number: {entry}")
            result.append(f"{name}={number:.12g}")
        elif name in BOOLEAN_PARAMETERS:
            if value.lower() not in {"true", "false"}:
                raise ValueError(f"{name} must be true or false")
            result.append(f"{name}={value.lower()}")
        else:
            raise ValueError(f"Unknown parameter: {name}")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--ids", help="IDs and ranges, e.g. 1,2,22,990-994")
    source.add_argument("--start", type=int, help="First ID (inclusive)")
    parser.add_argument("--end", type=int, help="Last ID (inclusive)")
    parser.add_argument(
        "--output", type=Path,
        default=Path(os.environ.get("GROOVER_OUTPUT_DIR", "output")),
    )
    parser.add_argument(
        "--set", action="append", default=[], metavar="NAME=VALUE",
        help="Override a supported OpenSCAD parameter",
    )
    parser.add_argument("--openscad", default="openscad")
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    try:
        if args.ids is not None:
            if args.end is not None:
                parser.error("--end cannot be combined with --ids")
            ids = parse_ids(args.ids)
        else:
            start = 1 if args.start is None else args.start
            end = 5 if args.end is None else args.end
            if not 0 <= start <= end <= 1023:
                parser.error("Require 0 <= start <= end <= 1023")
            ids = list(range(start, end + 1))
        overrides = build_overrides(args.set)
    except ValueError as exc:
        parser.error(str(exc))

    if not SCAD_FILE.is_file():
        parser.error(f"Missing model: {SCAD_FILE}")
    if not args.dry_run and shutil.which(args.openscad) is None:
        parser.error(f"OpenSCAD executable not found: {args.openscad}")

    args.output.mkdir(parents=True, exist_ok=True)
    completed = 0
    for disc_id in ids:
        for part in ("white", "black", "assembled"):
            path = args.output / f"D{disc_id:04d}_{part}.stl"
            if path.exists() and not args.overwrite:
                print(f"Skipping existing {path}; use --overwrite to replace")
                continue
            cmd = [
                args.openscad, "-o", str(path),
                "-D", f"disc_id={disc_id}",
                "-D", f'part="{part}"',
            ]
            for setting in overrides:
                cmd.extend(["-D", setting])
            cmd.append(str(SCAD_FILE))
            print(f"Generating {path}", flush=True)
            if args.dry_run:
                print("  ", " ".join(cmd))
                continue
            try:
                subprocess.run(cmd, check=True)
                if not path.exists() or path.stat().st_size == 0:
                    raise RuntimeError(f"Missing or empty STL: {path}")
            except (subprocess.CalledProcessError, RuntimeError, OSError) as exc:
                path.unlink(missing_ok=True)
                print(f"ERROR: {exc}", file=sys.stderr)
                return 1
            completed += 1
    print(f"Done: {completed} STL files generated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
