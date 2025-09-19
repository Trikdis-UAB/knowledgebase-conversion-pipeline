#!/bin/bash
set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 <input.docx>"; exit 1
fi

OUT_DIR="${OUT_DIR:-docs/manuals}"

# Get absolute paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
inp="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
base="$(basename "${inp%.docx}")"
doc_dir="${OUT_DIR}/${base}"

# Ensure filters exist
for f in strip-cover.lua strip-toc.lua promote-strong-top.lua normalize-headings.lua split-inline-images.lua convert-image-sizes.lua softwrap-tokens.lua clean-table-pipes.lua mark-two-col.lua strip-classes.lua fix-typography.lua fix-crossrefs.lua; do
  [ -f "$SCRIPT_DIR/$f" ] || { echo "Missing $f"; exit 1; }
done
# Check the new filter in filters subdirectory
[ -f "$SCRIPT_DIR/filters/flatten-two-cell-tables.lua" ] || { echo "Missing filters/flatten-two-cell-tables.lua"; exit 1; }

mkdir -p "$doc_dir"
pushd "$doc_dir" >/dev/null

pandoc "$inp" \
  -o "index.md" \
  -t commonmark_x+pipe_tables+attributes \
  --extract-media="." \
  --wrap=none \
  --markdown-headings=atx \
  --lua-filter="$SCRIPT_DIR/strip-cover.lua" \
  --lua-filter="$SCRIPT_DIR/strip-toc.lua" \
  --lua-filter="$SCRIPT_DIR/promote-strong-top.lua" \
  --lua-filter="$SCRIPT_DIR/filters/flatten-two-cell-tables.lua" \
  --lua-filter="$SCRIPT_DIR/normalize-headings.lua" \
  --lua-filter="$SCRIPT_DIR/split-inline-images.lua" \
  --lua-filter="$SCRIPT_DIR/convert-image-sizes.lua" \
  --lua-filter="$SCRIPT_DIR/softwrap-tokens.lua" \
  --lua-filter="$SCRIPT_DIR/clean-table-pipes.lua" \
  --lua-filter="$SCRIPT_DIR/mark-two-col.lua" \
  --lua-filter="$SCRIPT_DIR/strip-classes.lua" \
  --lua-filter="$SCRIPT_DIR/fix-typography.lua" \
  --lua-filter="$SCRIPT_DIR/fix-crossrefs.lua"

# If Pandoc made ./media/, flatten to current folder and fix links
if [ -d "media" ]; then
  echo "  Flattening media folder..."
  shopt -s nullglob
  for f in media/*; do mv "$f" .; done
  rmdir media
  # Rewrite ](media/xxx) -> ](xxx) and src="./media/xxx" -> src="xxx"
  sed -i '' 's#](\./media/#](#g' index.md
  sed -i '' 's#](media/#](#g' index.md
  sed -i '' 's#src="\./media/#src="#g' index.md
  sed -i '' 's#src="media/#src="#g' index.md
  echo "  Fixed image paths"
fi

# Fix any remaining error references
sed -i '' 's/Error! Reference source not found\./see the referenced section/g' index.md

# Clean up blockquotes in tables
sed -i '' 's/<blockquote>//g; s/<\/blockquote>//g' index.md

python3 "$SCRIPT_DIR/normalize-callouts.py" index.md
python3 "$SCRIPT_DIR/fix-relative-images.py" index.md

popd >/dev/null
echo "✅ Wrote: ${doc_dir}/index.md (images in same folder)"