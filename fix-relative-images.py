#!/usr/bin/env python3
"""Ensure relative image references use ./ prefix for stable resolution."""
from __future__ import annotations
import re
import sys
from pathlib import Path

if len(sys.argv) != 2:
    print("Usage: fix-relative-images.py <markdown-file>", file=sys.stderr)
    raise SystemExit(1)

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

def _mk_repl(match: re.Match[str]) -> str:
    prefix, target = match.groups()
    return f"{prefix}(./{target})"

# Markdown images/links `(image...)` -> `(./image...)`
markdown_pattern = re.compile(r"(!?\[[^\]]*\]\()(?!(?:\./|https?://|#))(image[^)]+)\)")
text = markdown_pattern.sub(lambda m: f"{m.group(1)}./{m.group(2)})", text)

# HTML img src attributes
html_pattern = re.compile(r"src=\"(?!(?:\./|https?://))(image[^\"]*)\"")
text = html_pattern.sub(lambda m: f"src=\"./{m.group(1)}\"", text)

path.write_text(text, encoding="utf-8")
