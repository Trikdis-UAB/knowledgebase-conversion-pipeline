#!/usr/bin/env python3
"""
Reduce excessive spacing in markdown files.

Removes multiple consecutive empty lines and reduces spacing in list sections
while preserving necessary formatting.
"""

import re
import sys
from pathlib import Path


def reduce_spacing(content: str) -> str:
    """Remove excessive empty lines while preserving structure."""

    lines = content.split('\n')
    output_lines = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Always add the current line
        output_lines.append(line)

        # If this line is empty, check how many empty lines follow
        if line.strip() == "":
            # Count consecutive empty lines
            empty_count = 0
            j = i + 1
            while j < len(lines) and lines[j].strip() == "":
                empty_count += 1
                j += 1

            # Skip excessive empty lines (keep max 1 empty line)
            if empty_count > 0:
                # Add at most one empty line
                if i > 0 and output_lines[-1].strip() != "":
                    # Only add empty line if previous line wasn't empty
                    pass  # We already added the first empty line
                else:
                    # Remove the empty line we just added since previous was also empty
                    output_lines.pop()

                # Skip all the additional empty lines
                i = j - 1

        i += 1

    # Clean up: remove multiple consecutive empty lines that might still exist
    final_lines = []
    prev_empty = False

    for line in output_lines:
        is_empty = line.strip() == ""

        if is_empty and prev_empty:
            # Skip this empty line (already have one)
            continue

        final_lines.append(line)
        prev_empty = is_empty

    return '\n'.join(final_lines)


def main(path: Path) -> None:
    """Process the markdown file to reduce spacing."""
    content = path.read_text(encoding="utf-8")
    reduced = reduce_spacing(content)
    path.write_text(reduced, encoding="utf-8")
    print(f"Reduced spacing in {path}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: reduce-spacing.py <markdown-file>", file=sys.stderr)
        raise SystemExit(1)
    main(Path(sys.argv[1]))