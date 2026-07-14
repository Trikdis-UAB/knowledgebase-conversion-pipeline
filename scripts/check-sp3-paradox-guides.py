#!/usr/bin/env python3
"""Validate generated SP3 Paradox companion guides against their manifest."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / "configs" / "sp3-paradox-guides.json"
IMAGE_REF = re.compile(r'(?:src=["\']|!\[[^\]]*\]\()(?P<path>[^"\')\s]+\.(?:png|jpe?g|webp))', re.IGNORECASE)
FORBIDDEN = ("Error! Reference source not found", "{.underline}", "## Contents", "## Turinys", "## Contenido", "## Содержание")
SOURCE_PATH_ALT = re.compile(r'alt="(?:Mac HD:|[A-Za-z]:\\)[^\"]*"')
MALFORMED_IMAGE_LINK = re.compile(r'\[\s*<img\b[^>]*>\s*\]')


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-root", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    return parser.parse_args()


def validate_guide(output_root: Path, guide: dict[str, object]) -> list[str]:
    folder = output_root / str(guide["destination"])
    index_path = folder / "index.md"
    errors: list[str] = []
    if not index_path.is_file():
        return [f"{guide['id']}: missing {index_path}"]

    text = index_path.read_text(encoding="utf-8")
    lines = text.splitlines()
    h1s = [line for line in lines if line.startswith("# ")]
    expected_h1 = f"# {guide['title']}"
    if h1s != [expected_h1]:
        errors.append(f"{guide['id']}: expected one H1 '{expected_h1}', found {h1s}")

    for term in guide["required_terms"]:
        if str(term).casefold() not in text.casefold():
            errors.append(f"{guide['id']}: missing required term '{term}'")
    headings = [line.lstrip("#").strip().casefold() for line in lines if line.startswith("#")]
    for section in guide["required_sections"]:
        if str(section).casefold() not in headings:
            errors.append(f"{guide['id']}: missing required section '{section}'")
    for forbidden in FORBIDDEN:
        if forbidden in text:
            errors.append(f"{guide['id']}: residual '{forbidden}'")
    if "# Security control panel “FLEXi” SP3" in text:
        errors.append(f"{guide['id']}: retained incorrect general SP3 title")
    if SOURCE_PATH_ALT.search(text):
        errors.append(f"{guide['id']}: retained source-path image alt text")
    if MALFORMED_IMAGE_LINK.search(text):
        errors.append(f"{guide['id']}: retained malformed image link")

    image_refs = [match.group("path") for match in IMAGE_REF.finditer(text)]
    if not image_refs:
        errors.append(f"{guide['id']}: no local images referenced")
    for image_ref in image_refs:
        image_path = folder / image_ref.removeprefix("./")
        if not image_path.is_file():
            errors.append(f"{guide['id']}: missing referenced image {image_ref}")
    return errors


def main() -> int:
    args = parse_args()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    failures: list[str] = []
    for guide in manifest["guides"]:
        errors = validate_guide(args.output_root, guide)
        if errors:
            failures.extend(errors)
        else:
            print(f"✓ {guide['id']} passed")
    if failures:
        print("\n".join(f"ERROR: {error}" for error in failures), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
