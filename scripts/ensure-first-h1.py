#!/usr/bin/env python3
"""
Ensure converted manuals have a top-level H1 title.

Some older DOCX sources (e.g., T16 manuals) start with a Description section
and never expose the product name as an H1.  MkDocs expects a leading H1 so the
navbar and cover image logic work the same way across manuals.

Heuristics:
  • If an H1 already exists, leave the document untouched.
  • Otherwise grab the first non-empty paragraph that is not a heading,
    admonition, or HTML block.
  • Truncate the paragraph before phrases like " yra " ("is" in Lithuanian) to
    isolate the product name.
  • Fallback to the first H2 heading text if no plain paragraph is suitable.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path


def has_h1(lines: list[str]) -> bool:
    return any(line.startswith("# ") for line in lines)


def candidate_from_paragraphs(lines: list[str]) -> str | None:
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("#"):
            continue
        if stripped.startswith("!!!"):
            continue
        if stripped.startswith("<"):
            continue
        if stripped.startswith("!"):
            continue
        if stripped.startswith("```"):
            continue
        return stripped
    return None


def candidate_from_headings(lines: list[str]) -> str | None:
    for line in lines:
        if line.startswith("## "):
            return line[3:].strip()
    return None


def normalize_candidate(text: str) -> str | None:
    text = text.strip()
    if not text:
        return None

    # Trim leading bullets or markers
    text = re.sub(r"^[\-–•]+\s+", "", text)

    # For Lithuanian paragraphs like "Radijo siųstuvas T16 yra ..."
    parts = re.split(r"\s+yra\s+", text, maxsplit=1)
    if parts and parts[0]:
        text = parts[0]

    text = text.rstrip(" .:-")
    return text or None


def ensure_h1(path: Path) -> None:
    lines = path.read_text(encoding="utf-8").splitlines()

    title_override = os.environ.get("DOCUMENT_TITLE", "").strip()
    if title_override:
        first_h1 = next((idx for idx, line in enumerate(lines) if line.startswith("# ")), None)

        # A leading H1 is a generated document title and can be replaced.  A
        # later H1 is a real section (as in the legacy Paradox user guide), so
        # retain it as an H2 beneath the supplied document title.
        if first_h1 is not None and all(not line.strip() for line in lines[:first_h1]):
            lines[first_h1] = f"# {title_override}"
        else:
            while lines and not lines[0].strip():
                lines.pop(0)
            lines = [f"# {title_override}", "", *lines]

        lines = [f"## {line[2:]}" if line.startswith("# ") and line != f"# {title_override}" else line for line in lines]
        path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
        return

    def dedupe_subheading(content: list[str]) -> None:
        first_heading = None
        for line in content:
            if line.startswith("# "):
                first_heading = line[2:].strip().rstrip(":").lower()
                break
        if not first_heading:
            return
        for idx, line in enumerate(content):
            if line.startswith("## "):
                sub = line[3:].strip().rstrip(":").lower()
                if sub == first_heading:
                    del content[idx]
                    if idx < len(content) and content[idx].strip() == "":
                        del content[idx]
                    break

    if lines and lines[0].strip().upper() == "# IMPORTANT!":
        candidate = candidate_from_headings(lines[1:]) or candidate_from_paragraphs(lines[1:])
        heading = normalize_candidate(candidate or "")
        if heading:
            lines[0] = f"# {heading}"
            normalized_heading = heading.lower().rstrip(":")
        else:
            normalized_heading = None
        # Drop the next standalone IMPORTANT! paragraph if it exists
        for idx in range(1, min(len(lines), 6)):
            if lines[idx].strip().upper() == "IMPORTANT!":
                del lines[idx]
                break
        if normalized_heading:
            dedupe_subheading(lines)
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        return

    if has_h1(lines):
        return

    candidate = candidate_from_paragraphs(lines)
    if candidate is None:
        candidate = candidate_from_headings(lines)

    heading = normalize_candidate(candidate or "")
    if heading is None:
        return  # Give up quietly, the downstream pipeline will handle fallback

    new_lines = [f"# {heading}", ""]

    # Insert cover image if image1.png exists and is not already referenced
    if "image1.png" not in "\n".join(lines):
        image_path = path.parent / "image1.png"
        if image_path.exists():
            new_lines.extend([
                '<div style="text-align: center;">',
                "",
                '<img src="./image1.png" alt="" width="400">',
                "",
                '</div>',
                ""
            ])

    new_lines.extend(lines)
    dedupe_subheading(new_lines)
    path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: ensure-first-h1.py <markdown-file>", file=sys.stderr)
        raise SystemExit(1)

    ensure_h1(Path(sys.argv[1]))


if __name__ == "__main__":
    main()
