#!/usr/bin/env python3
"""
Validate converted SP3 manual output directories.

This is a focused regression check for the 2025-12-08 multilingual SP3 pass.
"""

from pathlib import Path
import sys

IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg"}
LEGACY_ANCHORS = {
    "#Users_window": '<a id="Users_window"></a>',
    "#trikdisconfig-būsenos-juostos-aprašymas": '<a id="trikdisconfig-būsenos-juostos-aprašymas"></a>',
}
EXPECTED_TITLES = {
    "_EN_": '# Security control panel “FLEXi” SP3',
    "_LT_": '# Apsaugos centralė “FLEXi” SP3',
    "_ESP_": '# Panel de control FLEXi SP3',
    "_RU_": '# Охранная панель „FLEXI“ SP3',
}


def check_output_dir(output_dir: Path) -> list[str]:
    index_path = output_dir / "index.md"
    errors: list[str] = []

    if not output_dir.is_dir():
        return [f"{output_dir}: directory does not exist"]

    if not index_path.is_file():
        return [f"{output_dir}: missing index.md"]

    text = index_path.read_text(encoding="utf-8")
    lines = text.splitlines()
    h1_lines = [line for line in lines if line.startswith("# ")]
    image_files = [path for path in output_dir.iterdir() if path.suffix.lower() in IMAGE_SUFFIXES]

    if len(h1_lines) != 1:
        errors.append(f"{output_dir}: expected exactly 1 H1, found {len(h1_lines)}")

    if not h1_lines or "SP3" not in h1_lines[0]:
        errors.append(f"{output_dir}: missing SP3 product title H1")

    for marker, expected_title in EXPECTED_TITLES.items():
        if marker in output_dir.name and (not h1_lines or h1_lines[0].strip() != expected_title):
            errors.append(
                f"{output_dir}: expected H1 '{expected_title}', found '{h1_lines[0].strip() if h1_lines else 'MISSING'}'"
            )
            break

    if "Error! Reference source not found" in text:
        errors.append(f"{output_dir}: unresolved Word cross-reference remains")

    if "{.underline}" in text:
        errors.append(f"{output_dir}: residual {{.underline}} artifact remains")

    if any(line.startswith("> ####") for line in lines):
        errors.append(f"{output_dir}: residual quoted heading block remains")

    for legacy_ref, anchor_line in LEGACY_ANCHORS.items():
        if legacy_ref in text and anchor_line not in text:
            errors.append(f"{output_dir}: missing legacy anchor alias for {legacy_ref}")

    if not image_files:
        errors.append(f"{output_dir}: no extracted images found")
    elif not (output_dir / "image1.png").exists():
        errors.append(f"{output_dir}: expected image1.png cover asset is missing")

    return errors


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: check-sp3-conversion.py <output-dir> [<output-dir> ...]", file=sys.stderr)
        return 1

    failures: list[str] = []

    for raw_path in sys.argv[1:]:
        output_dir = Path(raw_path)
        errors = check_output_dir(output_dir)
        if errors:
            failures.extend(errors)
        else:
            print(f"✓ SP3 conversion checks passed for {output_dir}")

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
