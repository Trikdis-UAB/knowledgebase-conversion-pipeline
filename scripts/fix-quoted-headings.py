#!/usr/bin/env python3
"""
Normalize residual blockquote-wrapped headings in converted markdown.

Some SP3 outputs still contain a malformed sequence like:
    > ####
    >
    > #### SMS command list

This should become a normal markdown heading so MkDocs numbers it correctly.
"""

from pathlib import Path
import re
import sys

QUOTED_HEADING_RE = re.compile(r"^>\s*(#{2,6})\s+(.+?)\s*$")
EMPTY_QUOTED_HEADING_RE = re.compile(r"^>\s*(#{2,6})\s*$")
EMPTY_QUOTE_RE = re.compile(r"^>\s*$")


def normalize_quoted_headings(lines: list[str]) -> tuple[list[str], int]:
    fixed: list[str] = []
    replacements = 0
    index = 0

    while index < len(lines):
        line = lines[index]
        empty_heading = EMPTY_QUOTED_HEADING_RE.match(line)

        if empty_heading:
            hashes = empty_heading.group(1)
            cursor = index + 1
            while cursor < len(lines) and EMPTY_QUOTE_RE.match(lines[cursor]):
                cursor += 1

            if cursor < len(lines):
                titled_heading = QUOTED_HEADING_RE.match(lines[cursor])
                if titled_heading and titled_heading.group(1) == hashes:
                    fixed.append(f"{hashes} {titled_heading.group(2).strip()}")
                    replacements += 1
                    index = cursor + 1
                    continue

        titled_heading = QUOTED_HEADING_RE.match(line)
        if titled_heading:
            fixed.append(f"{titled_heading.group(1)} {titled_heading.group(2).strip()}")
            replacements += 1
            index += 1
            continue

        fixed.append(line)
        index += 1

    return fixed, replacements


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: fix-quoted-headings.py <markdown-file>", file=sys.stderr)
        return 1

    path = Path(sys.argv[1])
    lines = path.read_text(encoding="utf-8").splitlines()
    fixed_lines, replacements = normalize_quoted_headings(lines)

    if fixed_lines != lines:
        path.write_text("\n".join(fixed_lines) + "\n", encoding="utf-8")

    if replacements:
        print(f"✓ Fixed {replacements} quoted heading block(s) in {path}")
    else:
        print(f"✓ No quoted heading blocks found in {path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
