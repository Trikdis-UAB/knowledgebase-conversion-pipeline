#!/bin/bash
set -euo pipefail
OUT_DIR="${OUT_DIR:-docs/manuals}"

# Get absolute paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Ensure filters exist
for f in strip-cover.lua strip-toc.lua promote-strong-top.lua normalize-headings.lua split-inline-images.lua softwrap-tokens.lua clean-table-pipes.lua mark-two-col.lua strip-classes.lua fix-typography.lua fix-crossrefs.lua; do
  [ -f "$SCRIPT_DIR/$f" ] || { echo "Missing $f"; exit 1; }
done
# Check the new filter in filters subdirectory
[ -f "$SCRIPT_DIR/filters/flatten-two-cell-tables.lua" ] || { echo "Missing filters/flatten-two-cell-tables.lua"; exit 1; }

count=0
shopt -s nullglob

for f in *.docx "docx manuals"/*.docx; do
  [ -f "$f" ] || continue
  
  # Get absolute path for input
  inp="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
  base="$(basename "${f%.docx}")"
  doc_dir="${OUT_DIR}/${base}"
  
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
    --lua-filter="$SCRIPT_DIR/softwrap-tokens.lua" \
    --lua-filter="$SCRIPT_DIR/clean-table-pipes.lua" \
    --lua-filter="$SCRIPT_DIR/mark-two-col.lua" \
    --lua-filter="$SCRIPT_DIR/strip-classes.lua" \
    --lua-filter="$SCRIPT_DIR/fix-typography.lua" \
    --lua-filter="$SCRIPT_DIR/fix-crossrefs.lua"

  # If Pandoc made ./media/, flatten to current folder and fix links
  if [ -d "media" ]; then
    shopt -s nullglob
    for x in media/*; do mv "$x" .; done
    rmdir media
    # Rewrite ](media/xxx) -> ](xxx) and src="./media/xxx" -> src="xxx"
    sed -i '' 's#](\./media/#](#g' index.md
    sed -i '' 's#](media/#](#g' index.md
    sed -i '' 's#src="\./media/#src="#g' index.md
    sed -i '' 's#src="media/#src="#g' index.md
  fi
  
  # Fix any remaining error references
  sed -i '' 's/Error! Reference source not found\./see the referenced section/g' index.md
  
  # Clean up blockquotes in tables
  sed -i '' 's/<blockquote>//g; s/<\/blockquote>//g' index.md

  popd >/dev/null
  echo "✓ ${doc_dir}/index.md"
  ((count++))
done

echo "Batch completed: $count files"