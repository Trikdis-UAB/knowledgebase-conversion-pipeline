#!/usr/bin/env python3
"""Convert and curate the eight localized SP3 Paradox companion guides."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / "configs" / "sp3-paradox-guides.json"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-root", type=Path, required=True, help="Destination root containing locale directories")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    return parser.parse_args()


def clean_generated_guide(index_path: Path, guide: dict[str, object]) -> None:
    lines = index_path.read_text(encoding="utf-8").splitlines()
    contents_headings = {"## Contents", "## Turinys", "## Contenido", "## Содержание"}
    lines = [line for line in lines if line.strip() not in contents_headings]

    trim_after = str(guide.get("trim_after", "")).casefold()
    if trim_after:
        for index, line in enumerate(lines):
            if trim_after in line.casefold():
                lines = lines[:index]
                break

    section_marker = str(guide.get("section_marker", "")).casefold()
    section_heading = str(guide.get("section_heading", ""))
    if section_marker and section_heading:
        for index, line in enumerate(lines):
            if section_marker in line.casefold():
                lines[index:index] = ["", f"## {section_heading}", ""]
                break

    # Pandoc preserves the source DOCX's local Windows path as this cover
    # image's alt text. Keep useful alt text without exposing an author path.
    lines = [
        re.sub(r'alt="[A-Za-z]:\\[^\"]+"', 'alt="FLEXi SP3 and RTX3 wireless receiver"', line)
        for line in lines
    ]

    content = "\n".join(lines)
    content = re.sub(r'alt="(?:Mac HD:|[A-Za-z]:\\)[^\"]*"', 'alt=""', content)
    # Symbols from the Word keypad diagrams were emitted as image links with no
    # destination. Preserve the symbols as inline images instead.
    content = re.sub(r'\[\s*(<img\b[^>]*?/?>)\s*\]', r'\1', content)
    content = "\n".join(line.rstrip() for line in content.splitlines()).rstrip() + "\n"
    index_path.write_text(content, encoding="utf-8")


def main() -> int:
    args = parse_args()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    guides = manifest["guides"]
    output_root = args.output_root.resolve()
    output_root.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="sp3-paradox-guides-") as temp_dir:
        staging_root = Path(temp_dir)
        for guide in guides:
            source = ROOT / str(guide["source"])
            if not source.is_file():
                raise FileNotFoundError(f"Source document is missing: {source}")

            env = os.environ.copy()
            env.update(
                {
                    "OUT_DIR": str(staging_root),
                    "DOCUMENT_TITLE": str(guide["title"]),
                    "KEYPAD_MODE": "1" if guide["kind"] == "user" else "0",
                }
            )
            subprocess.run(
                [str(ROOT / "scripts" / "convert-single.sh"), str(source)],
                cwd=ROOT,
                env=env,
                check=True,
            )

            converted = staging_root / source.stem
            if not converted.is_dir():
                raise RuntimeError(f"Converter did not create {converted}")

            destination = output_root / str(guide["destination"])
            if destination.exists():
                shutil.rmtree(destination)
            shutil.copytree(converted, destination)
            clean_generated_guide(destination / "index.md", guide)
            print(f"✓ {guide['id']}: {destination}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
