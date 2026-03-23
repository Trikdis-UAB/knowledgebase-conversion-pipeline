#!/usr/bin/env python3
"""
Normalize any residual `[text]{.underline}` fragments left after conversion.

The Pandoc/Lua path handles most underline markup, but some wrapped SP3 note
content still survives as literal markdown attributes late in the pipeline.
This pass rewrites the remaining fragments to <u>...</u> while preserving any
surrounding emphasis markers in the source text.
"""

from pathlib import Path
import sys

UNDERLINE_ATTR = "{.underline}"


def replace_residual_underlines(text: str) -> tuple[str, int]:
    """Replace residual `[...]{.underline}` patterns, including multiline ones."""
    result: list[str] = []
    index = 0
    replacements = 0
    text_len = len(text)

    while index < text_len:
        if text[index] != "[":
            result.append(text[index])
            index += 1
            continue

        cursor = index + 1
        depth = 1

        while cursor < text_len and depth:
            char = text[cursor]
            if char == "[":
                depth += 1
            elif char == "]":
                depth -= 1
            cursor += 1

        if depth:
            result.append(text[index])
            index += 1
            continue

        if not text.startswith(UNDERLINE_ATTR, cursor):
            result.append(text[index:cursor])
            index = cursor
            continue

        content = text[index + 1 : cursor - 1]
        result.append(f"<u>{content}</u>")
        index = cursor + len(UNDERLINE_ATTR)
        replacements += 1

    return "".join(result), replacements


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: normalize-residual-underlines.py <markdown-file>", file=sys.stderr)
        return 1

    path = Path(sys.argv[1])
    original = path.read_text(encoding="utf-8")
    updated, replacements = replace_residual_underlines(original)

    if updated != original:
        path.write_text(updated, encoding="utf-8")

    if replacements:
        print(f"✓ Normalized {replacements} residual underline fragment(s) in {path}")
    else:
        print(f"✓ No residual underline fragments found in {path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
