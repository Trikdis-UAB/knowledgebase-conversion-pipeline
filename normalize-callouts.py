#!/usr/bin/env python3
"""Normalize GitHub-style callouts in Markdown output.

Converts blockquotes that start with `[!NOTE]`, `[!IMPORTANT]`, etc. into
MkDocs/Material admonition syntax (`!!! note`).

It also collapses repeated blockquote prefixes (`> > >`) down to a single `>`
so the resulting Markdown stays readable and Typora-compatible.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import List

SUPPORTED = {
    "NOTE": "note",
    "IMPORTANT": "important",
    "WARNING": "warning",
    "CAUTION": "caution",
    "TIP": "tip",
}

CALL_RE = re.compile(r"^>\s*\[!([A-Z]+)\]\s*(.*)$")
QUOTE_RE = re.compile(r"^>\s?(.*)$")
MULTI_QUOTE_RE = re.compile(r"^(?:>\s*)+(.*)$")


def normalize_quotes(lines: List[str]) -> List[str]:
    """Collapse repeated `>` prefixes down to a single `>`."""

    normalized: List[str] = []
    for line in lines:
        stripped = line.lstrip()
        if not stripped.startswith(">"):
            normalized.append(line)
            continue
        # Preserve leading indentation, collapse repeated markers
        indent = line[: len(line) - len(stripped)]
        match = MULTI_QUOTE_RE.match(stripped)
        if match:
            content = match.group(1)
            normalized.append(f"{indent}> {content}".rstrip())
        else:
            normalized.append(line)
    return normalized


def convert_callouts(lines: List[str]) -> List[str]:
    output: List[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        match = CALL_RE.match(line)
        if not match:
            output.append(line)
            i += 1
            continue

        callout_type = match.group(1).upper()
        mapped = SUPPORTED.get(callout_type, "note")
        title = match.group(2).strip()

        if title:
            output.append(f"!!! {mapped} \"{title}\"")
        else:
            output.append(f"!!! {mapped}")

        i += 1
        # Gather the blockquote body lines
        body_lines: List[str] = []
        while i < len(lines):
            cont = QUOTE_RE.match(lines[i])
            if not cont:
                break
            body_lines.append(cont.group(1))
            i += 1

        # Trim leading/trailing empty lines inside the body for cleaner output
        while body_lines and body_lines[0].strip() == "":
            body_lines.pop(0)
        while body_lines and body_lines[-1].strip() == "":
            body_lines.pop()

        if body_lines:
            for body_line in body_lines:
                output.append(f"    {body_line.rstrip()}")
        else:
            output.append("    ")

        # Ensure a blank line after the admonition for Markdown parsers
        if i < len(lines) and lines[i].strip():
            output.append("")

    return output


def main(path: Path) -> None:
    original = path.read_text(encoding="utf-8").splitlines()
    normalized = normalize_quotes(original)
    converted = convert_callouts(normalized)
    path.write_text("\n".join(converted) + "\n", encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: normalize-callouts.py <markdown-file>", file=sys.stderr)
        raise SystemExit(1)
    main(Path(sys.argv[1]))
