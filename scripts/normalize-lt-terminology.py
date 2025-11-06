#!/usr/bin/env python3
"""Normalize Lithuanian terminology for cellular equipment manuals."""

import sys

REPLACEMENTS = [
    ("Ląstelinio ryšio komunikatorius", "Mobiliojo ryšio komunikatorius"),
    ("ląstelinio ryšio komunikatorius", "mobiliojo ryšio komunikatorius"),
    ("ląstelinio ryšio", "mobiliojo ryšio"),
]


def normalize(text: str) -> str:
    for old, new in REPLACEMENTS:
        text = text.replace(old, new)
    return text


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: python3 normalize-lt-terminology.py <file.md>")
        sys.exit(1)

    path = sys.argv[1]
    try:
        with open(path, "r", encoding="utf-8") as fh:
            content = fh.read()
        updated = normalize(content)
        if updated != content:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(updated)
            print(f"✓ Normalized Lithuanian terminology in {path}")
        else:
            print(f"✓ Lithuanian terminology already normalized in {path}")
    except OSError as exc:
        print(f"Error processing {path}: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
