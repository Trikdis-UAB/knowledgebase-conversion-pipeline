#!/usr/bin/env python3
"""
Fix inline MkDocs admonition lines that contain escaped headings.

Some converted manuals have lines like:
    !!! note Text ... \## Section Title
or note body lines such as:
        Additional text ... \#### Subsection

MkDocs treats the escaped heading markers literally, so the heading content
remains inside the admonition instead of starting a new section.  This script
splits those lines by unescaping the heading, keeping the admonition text, and
emitting a proper heading on the following line.

The transformation is safe to run multiple times.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import List, Tuple

ADMONITION_PREFIX_RE = re.compile(
    r'^(!!! (?:note|warning|tip|caution|important)(?: "[^"]*")?)(.*)$'
)
HEADING_ESCAPE_RE = re.compile(r'(.*?)\\(#{2,6})\s*(.*)')


def split_heading(text: str) -> Tuple[str, str | None]:
    """Return (note_text, heading_line) for a string containing an escaped heading."""
    match = HEADING_ESCAPE_RE.match(text)
    if not match:
        return text.rstrip(), None

    before = match.group(1).rstrip()
    hashes = match.group(2)
    heading_text = match.group(3).strip()
    heading_line = hashes if not heading_text else f"{hashes} {heading_text}"
    return before, heading_line


def process_admonition_line(line: str) -> Tuple[List[str], bool]:
    """Process an admonition head line, returning new lines and whether the body continues."""
    match = ADMONITION_PREFIX_RE.match(line)
    if not match:
        return [line], False

    prefix, rest = match.groups()
    rest = rest.lstrip()
    if not rest:
        return [prefix], True

    before, heading = split_heading(rest)
    output = [prefix]

    if heading:
        if before:
            output.append(f"    {before}")
        output.append("")
        output.append(heading)
        return output, False

    output.append(f"    {before}" if before else "    ")
    return output, True


def process_body_line(line: str) -> Tuple[List[str], bool]:
    """Process an indented admonition body line."""
    content = line[4:]
    before, heading = split_heading(content)

    if heading:
        output: List[str] = []
        if before:
            output.append(f"    {before}")
        output.append("")
        output.append(heading)
        return output, False

    return [line], True


def fix_file(path: Path) -> None:
    lines = path.read_text(encoding="utf-8").splitlines()
    fixed: List[str] = []
    in_admonition = False

    for line in lines:
        if in_admonition and line.startswith("    "):
            processed, still_in = process_body_line(line)
            fixed.extend(processed)
            in_admonition = still_in
            continue

        processed, still_in = process_admonition_line(line)
        if processed != [line]:
            fixed.extend(processed)
            in_admonition = still_in
            continue

        fixed.append(line)
        in_admonition = False

    path.write_text("\n".join(fixed) + "\n", encoding="utf-8")


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: fix-inline-admonition-headings.py <markdown-file>", file=sys.stderr)
        raise SystemExit(1)

    fix_file(Path(sys.argv[1]))


if __name__ == "__main__":
    main()
