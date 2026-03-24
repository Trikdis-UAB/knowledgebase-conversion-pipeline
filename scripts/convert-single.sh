#!/bin/bash
set -euo pipefail

# Document conversion pipeline for TRIKDIS manuals
#
# GitHub Alerts: This pipeline converts GitHub alerts (> [!NOTE], > [!IMPORTANT])
# from DOCX to markdown format. The target MkDocs site MUST have markdown-callouts
# extension configured to render these properly. See GITHUB_ALERTS_CONFIG.md for details.
#
# Table Structure: Automatically fixes malformed table structures from DOCX conversion
# including H1 tags in cells, rowspan issues, and empty rows. See TABLE_STRUCTURE_FIX.md
# for details. This ensures tables display properly with horizontal headers in MkDocs.

if [ $# -eq 0 ]; then
  echo "Usage: $0 <input.docx>"; exit 1
fi

OUT_DIR="${OUT_DIR:-docs/manuals}"

# Get absolute paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
FILTER_DIR="${ROOT_DIR}/lua-filters"
inp="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
base="$(basename "${inp%.docx}")"
doc_dir="${OUT_DIR}/${base}"

# Enable keypad-specific handling automatically for keypad manuals unless overridden.
KEYPAD_MODE="${KEYPAD_MODE:-}"
if [ -z "$KEYPAD_MODE" ]; then
  case "$base" in
    "SK-LCD button"*|"SK-LCD TouchPad"*|"SK-LED button"*|"SK-LED TouchPad"*|"FLEXI_SK_"*)
      KEYPAD_MODE=1
      ;;
    *)
      KEYPAD_MODE=0
      ;;
  esac
fi
if [ "$KEYPAD_MODE" != "0" ] && [ "$KEYPAD_MODE" != "1" ]; then
  echo "KEYPAD_MODE must be 0 or 1 (got: $KEYPAD_MODE)" >&2
  exit 1
fi

# Ensure filters exist
for f in strip-cover.lua strip-toc.lua promote-strong-top.lua demote-extra-h1.lua fix-numbered-heading-levels.lua normalize-headings.lua move-first-image-to-description.lua split-inline-images.lua reposition-sentence-splitting-images.lua convert-image-sizes.lua softwrap-tokens.lua clean-table-pipes.lua mark-two-col.lua convert-underline.lua remove-unwanted-blockquotes.lua maintain-list-continuity.lua strip-classes.lua fix-typography.lua bold-list-titles.lua fix-crossrefs.lua clean-html-blocks.lua unwrap-table-blockquotes.lua remove-standalone-asterisks.lua fix-rowspan-headers.lua flatten-instruction-tables.lua collapse-spacer-columns.lua convert-keypad-layout.lua promote-keypad-headings.lua flatten-layout-tables.lua scale-inline-icons.lua; do
  [ -f "$FILTER_DIR/$f" ] || { echo "Missing $f"; exit 1; }
done
# Check the filters in filters subdirectory
[ -f "$FILTER_DIR/convert-legend-tables-ordered-lists.lua" ] || { echo "Missing lua-filters/convert-legend-tables-ordered-lists.lua"; exit 1; }
[ -f "$FILTER_DIR/flatten-two-cell-tables.lua" ] || { echo "Missing lua-filters/flatten-two-cell-tables.lua"; exit 1; }

mkdir -p "$doc_dir"
pushd "$doc_dir" >/dev/null

keypad_filters_after_warning=()
keypad_filters_after_flatten=()
keypad_filters_after_image_sizes=()
if [ "$KEYPAD_MODE" = "1" ]; then
  keypad_filters_after_warning=(
    --lua-filter="$FILTER_DIR/collapse-spacer-columns.lua"
    --lua-filter="$FILTER_DIR/convert-keypad-layout.lua"
    --lua-filter="$FILTER_DIR/promote-keypad-headings.lua"
  )
  keypad_filters_after_flatten=(
    --lua-filter="$FILTER_DIR/flatten-layout-tables.lua"
  )
  keypad_filters_after_image_sizes=(
    --lua-filter="$FILTER_DIR/scale-inline-icons.lua"
  )
fi

pandoc "$inp" \
  -o "index.md" \
  -t gfm \
  --extract-media="." \
  --wrap=none \
  --markdown-headings=atx \
  --lua-filter="$FILTER_DIR/strip-cover.lua" \
  --lua-filter="$FILTER_DIR/strip-toc.lua" \
  --lua-filter="$FILTER_DIR/map-docx-heading-levels.lua" \
  --lua-filter="$FILTER_DIR/fix-numbered-heading-levels.lua" \
  --lua-filter="$FILTER_DIR/promote-strong-top.lua" \
  --lua-filter="$FILTER_DIR/demote-extra-h1.lua" \
  --lua-filter="$FILTER_DIR/remove-table-widths.lua" \
  --lua-filter="$FILTER_DIR/convert-warning-tables.lua" \
  ${keypad_filters_after_warning[@]:+${keypad_filters_after_warning[@]}} \
  --lua-filter="$FILTER_DIR/convert-legend-tables-ordered-lists.lua" \
  --lua-filter="$FILTER_DIR/flatten-two-cell-tables.lua" \
  --lua-filter="$FILTER_DIR/flatten-instruction-tables.lua" \
  ${keypad_filters_after_flatten[@]:+${keypad_filters_after_flatten[@]}} \
  --lua-filter="$FILTER_DIR/unwrap-table-blockquotes.lua" \
  --lua-filter="$FILTER_DIR/convert-image-tables.lua" \
  --lua-filter="$FILTER_DIR/normalize-headings.lua" \
  --lua-filter="$FILTER_DIR/strip-manual-heading-numbers.lua" \
  --lua-filter="$FILTER_DIR/promote-centered-bold.lua" \
  --lua-filter="$FILTER_DIR/normalize-sp3-title.lua" \
  --lua-filter="$FILTER_DIR/move-first-image-to-description.lua" \
  --lua-filter="$FILTER_DIR/split-inline-images.lua" \
  --lua-filter="$FILTER_DIR/reposition-sentence-splitting-images.lua" \
  --lua-filter="$FILTER_DIR/convert-image-sizes.lua" \
  ${keypad_filters_after_image_sizes[@]:+${keypad_filters_after_image_sizes[@]}} \
  --lua-filter="$FILTER_DIR/softwrap-tokens.lua" \
  --lua-filter="$FILTER_DIR/remove-empty-table-columns.lua" \
  --lua-filter="$FILTER_DIR/clean-table-pipes.lua" \
  --lua-filter="$FILTER_DIR/mark-two-col.lua" \
  --lua-filter="$FILTER_DIR/convert-underline.lua" \
  --lua-filter="$FILTER_DIR/convert-blockquote-headings.lua" \
  --lua-filter="$FILTER_DIR/remove-unwanted-blockquotes.lua" \
  --lua-filter="$FILTER_DIR/unwrap-post-image-blockquotes.lua" \
  --lua-filter="$FILTER_DIR/insert-protegus-buttons.lua" \
  --lua-filter="$FILTER_DIR/remove-download-banners.lua" \
  --lua-filter="$FILTER_DIR/rewrite-protegus-links.lua" \
  --lua-filter="$FILTER_DIR/maintain-list-continuity.lua" \
  --lua-filter="$FILTER_DIR/strip-classes.lua" \
  --lua-filter="$FILTER_DIR/fix-typography.lua" \
  --lua-filter="$FILTER_DIR/bold-list-titles.lua" \
  --lua-filter="$FILTER_DIR/fix-html-tags.lua" \
  --lua-filter="$FILTER_DIR/fix-crossrefs.lua" \
  --lua-filter="$FILTER_DIR/remove-standalone-asterisks.lua" \
  --lua-filter="$FILTER_DIR/fix-admonition-lists.lua" \
  --lua-filter="$FILTER_DIR/strip-admonition-quotes.lua" \
  --lua-filter="$FILTER_DIR/reduce-excess-strong.lua" \
  --lua-filter="$FILTER_DIR/unwrap-paragraph-strong.lua" \
  --lua-filter="$FILTER_DIR/relocate-warranty.lua" \
  --lua-filter="$FILTER_DIR/clean-html-blocks.lua"

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

# Extract Protegus app store button images (by document position)
python3 "$SCRIPT_DIR/extract-protegus-buttons.py" "$inp" . 2>/dev/null || true

# Fix any remaining error references
sed -i '' 's/Error! Reference source not found\./see the referenced section/g' index.md

# Fix SP3-style H2 title with bold to H1 without bold (if at start of document)
# Pattern: ## **Title** → # Title (only for first heading)
sed -i '' '1,/^##/{s/^## \*\*\([^*]*\)\*\*$/# \1/;}' index.md

# DISABLED: Image centering now handled by move-first-image-to-description.lua filter
# This was creating duplicate centered images
# sed -i '' '1,/^## Description/{ s#^!\[GT Cellular Communicator\](./image1.png)$#<div style="text-align: center;">\n  <img src="./image1.png" alt="GT Cellular Communicator" width="400">\n</div>#; }' index.md

# Clean up blockquotes in tables
sed -i '' 's/<blockquote>//g; s/<\/blockquote>//g' index.md

# Fix HTML blocks with {=html} tags that prevent proper rendering in MkDocs
sed -i '' 's/`<img \([^`]*\)>`{=html}/<img \1>/g' index.md

python3 <<'PY'
import re
from pathlib import Path
index = Path('index.md')
text = index.read_text()
updated, count = re.subn(r'`(<img[^`]+>)`\{=html\}', r'\1', text)
if count:
    index.write_text(updated)
PY

# Fix underlined text with HTML tags to proper markdown underline
sed -i '' 's/`<u>`{=html}\([^`]*\)`<\/u>`{=html}/<u>\1<\/u>/g' index.md

# Fix escaped apostrophes in text (remove backslashes before single quotes)
sed -i '' "s/\\\\'/'/g" index.md

# Fix escaped quotes (remove backslashes before double quotes)
sed -i '' 's/\\"/"/g' index.md

# Fix escaped angle brackets in Annex conversion table (\<z\> → <z>, \<v\> → <v>, \<n\> → <n>)
sed -i '' 's/\\</</g; s/\\>/>/g' index.md

# Remove stray pipe characters from table cells (author formatting artifact from DOCX)
# DISABLED: This was too aggressive and was removing legitimate table column separators
# The html-tables-to-pipes.py script now handles this properly
# Pattern 1: " | " between any text → " " (just space)
# sed -i '' 's/ | / /g' index.md
# Pattern 2: trailing " |" at end of line or before tags → remove entirely
# sed -i '' 's/ |$//' index.md
# sed -i '' 's/ |</</g' index.md

# Remove table separator artifacts from DOCX (equal signs and plus)
# Pattern: "Model ======...+ " → "Model "
sed -i '' 's/Model [=]+\+ /Model /g' index.md

# Remove duplicate heading IDs like {#id .class} {#id-id-.class}
# Pattern: {#something} {#something-something-.class} → {#something}
sed -i '' -E 's/\{#([^}]+)\} \{#[^}]+\}/{#\1}/g' index.md

# Remove HTML comment artifacts (<!-- -->)
sed -i '' 's/<!-- -->//g' index.md

# Remove orphaned blockquote markers left inside admonition blocks
sed -i '' 's/^    > /    /' index.md

python3 <<'PY'
from pathlib import Path
index = Path('index.md')
text = index.read_text()
updated = text.replace('\n    > ', '\n    ')
updated = updated.replace('\n    >', '\n    ')
if updated != text:
    index.write_text(updated)
PY

python3 <<'PY'
import re
from pathlib import Path
index = Path('index.md')
lines = index.read_text().splitlines()
for i, line in enumerate(lines):
    if line.startswith('    >'):
        if line.startswith('    > '):
            lines[i] = '    ' + line[6:]
        else:
            lines[i] = '    ' + line[4:].lstrip('>')
    if 'El **' in line:
        lines[i] = re.sub(r'El \*\*(.+?)\*\*', r'El \1', lines[i], count=1)
index.write_text('\n'.join(lines) + '\n')
PY

python3 <<'PY'
from pathlib import Path
index = Path('index.md')
lines = index.read_text().splitlines()
changed = False
for i, line in enumerate(lines):
    if line.startswith('    >'):
        if line.startswith('    > '):
            lines[i] = '    ' + line[6:]
        else:
            lines[i] = '    ' + line[4:].lstrip('>')
        changed = True
if changed:
    index.write_text('\n'.join(lines) + '\n')
PY

python3 <<'PY'
from pathlib import Path
index = Path('index.md')
lines = index.read_text().splitlines()
def has_cover_tail(seq):
    if len(seq) < 3:
        return False
    return (seq[-3].strip().startswith('<div') and 'text-align: center' in seq[-3]
            and 'image1.png' in seq[-2] and seq[-1].strip() == '</div>')
while has_cover_tail(lines):
    lines = lines[:-3]
if lines:
    index.write_text('\n'.join(lines) + '\n')
PY

# Remove duplicate product images wrapped in <div> tags (keeps only the one after H1 title)
# This removes standalone <div><img src="imageN.png" ... width="400"></div> blocks (before ./ is added)
# The H1 image is added later by sed, so this safely removes all duplicates
perl -i -0777 -pe 's/<div>[\s\n]*<img\s+src="(?:\.\/)?(image[1-5]\.png)"[^>]*width="400"[^>]*>[\s\n]*<\/div>[\s\n]*/\n/g' index.md

python3 <<'PY'
from pathlib import Path
index = Path('index.md')
text = index.read_text()
updated = text.replace('\n    > ', '\n    ').replace('\n    >', '\n    ')
if updated != text:
    index.write_text(updated)
PY

# Fix title formatting - make "Works with Protegus2 app:" bold like other titles
sed -i '' 's/^Works with Protegus2 app:/**Works with Protegus2 app:**/g' index.md

# Fix title formatting - make "Reporting to the security company's central monitoring station (CMS):" bold
# Wrap the entire line with ** at both start and end
sed -i '' 's/^Reporting to the security company.*central monitoring station (CMS):/**&**/' index.md

# Fix Features section structure - change from bold to H3 (subsection) and make first line bold
sed -i '' 's/^\*\*Features\*\*$/### Features/g' index.md
sed -i '' 's/^Connects to the control panel'\''s serial or keyboard bus or telephone line (TIP\/RING)\.$/\*\*Connects to the control panel'\''s serial or keyboard bus or telephone line (TIP\/RING).\*\*/g' index.md

# Note: H1 title is now automatically generated by promote-strong-top.lua filter
# It extracts the product name from the cover page and creates proper title

# Normalize heading levels: ALL section headings should be H2, not H1
# Heading level management now handled by demote-extra-h1.lua filter during Pandoc processing
# The Lua filter ensures only the first H1 (product title) remains, all others are demoted to H2

# Fix heading hierarchy using Word classes and numbered headings
# - Python script handles unnumbered headings with Word classes (.2-Po-Pag)
# - Lua filter handles numbered headings in text (11.1 Title)
python3 "$SCRIPT_DIR/fix-heading-hierarchy.py" index.md
python3 "$SCRIPT_DIR/ensure-first-h1.py" index.md

# Add centered product image after H1 title (must run AFTER heading normalization)
# Works for all product types: Communicators, Alarm Panels, etc.
sed -i '' '/^# .*Alarm Panel$/a\
\
<div style="text-align: center;">\
  <img src="./image1.png" alt="Product Image" width="400">\
</div>
' index.md
sed -i '' '/^# .*Cellular Communicator$/a\
\
<div style="text-align: center;">\
  <img src="./image1.png" alt="Product Image" width="400">\
</div>
' index.md
sed -i '' '/^# .*Transmitter$/a\
\
<div style="text-align: center;">\
  <img src="./image1.png" alt="Product Image" width="400">\
</div>
' index.md
sed -i '' '/^# .*Si[uų]stuvas .*$/a\
\
<div style="text-align: center;">\
  <img src="./image1.png" alt="Product Image" width="400">\
</div>
' index.md

# Remove excessive bold/italic formatting from Description opening paragraph
# First remove all bold-italic (***text***) → (text)
sed -i '' 's/\*\*\*\([^*][^*]*[^*]\)\*\*\*/\1/g' index.md
# Then clean up nested bold/italic: **The *text* word** → The text word
sed -i '' 's/^\*\*The \*\([^*]*\) control panel\*\*/The \1 control panel/g' index.md

# Fix GitHub-style alerts by removing backslash escaping from square brackets
sed -i '' 's/\\\[/[/g; s/\\\]/]/g' index.md

# Make first sentence bold in section 2.5 (gate schematic section)
sed -i '' '/^### Schematic for connecting an automatic gate opener/{
  n
  n
  s/^All wiring should be done with the power supply disconnected\.$/\*\*All wiring should be done with the power supply disconnected.\*\*/
}' index.md

# Unwrap blockquotes after schematic image in section 2.5
# Pattern: After image10.png, remove blockquote markers from following lines
perl -i -0777 -pe '
  s/(image10\.png[^\n]*\n\n)> ([^\n]+\n)>\n> ([^\n]+)/$1$2\n$3/
' index.md

# Convert GitHub-style alerts to MkDocs admonitions format
sed -i '' 's/> \[!NOTE\]/!!! note/g' index.md
sed -i '' 's/> \[!IMPORTANT\]/!!! warning "Important"/g' index.md
sed -i '' 's/> \[!WARNING\]/!!! warning/g' index.md
sed -i '' 's/> \[!TIP\]/!!! tip/g' index.md
sed -i '' 's/> \[!CAUTION\]/!!! warning "Caution"/g' index.md

# Fix admonition formatting (proper indentation)
python3 "$SCRIPT_DIR/fix_admonitions.py" index.md
python3 "$SCRIPT_DIR/fix-inline-admonition-headings.py" index.md

# Fix table structure issues (H1 in cells, empty rows, malformed headers)
python3 "$SCRIPT_DIR/fix_table_structure.py" index.md

# Convert HTML tables to pipe tables for human readability (AFTER table structure fixes)
# Note: Legend tables with ordered lists are handled by convert-legend-tables-ordered-lists.lua filter
echo "Converting HTML tables to pipe tables..."
python3 "$SCRIPT_DIR/html-tables-to-pipes.py" index.md
if [ "$KEYPAD_MODE" = "1" ]; then
  python3 "$SCRIPT_DIR/rewrite_keypad_tables.py" index.md
fi

# Expand multi-state tables (tables with <br> tags) into separate rows
echo "Expanding multi-state tables..."
python3 "$SCRIPT_DIR/expand-multi-state-tables.py" index.md

# Convert underline markers to HTML tags
# The convert-underline.lua filter uses special markers (⟪U⟫ and ⟪/U⟫) that survive GFM conversion
# Now convert them to proper <u> tags
echo "Converting underline markers to HTML tags..."
sed -i '' 's/⟪U⟫/<u>/g; s/⟪\/U⟫/<\/u>/g' index.md

python3 "$SCRIPT_DIR/normalize-callouts.py" index.md
python3 "$SCRIPT_DIR/fix-relative-images.py" index.md
python3 "$SCRIPT_DIR/fix-list-continuity.py" index.md
python3 "$SCRIPT_DIR/reduce-spacing.py" index.md
python3 "$SCRIPT_DIR/fix-inline-admonition-headings.py" index.md

# Remove duplicate cover images (safety net for edge cases)
python3 "$SCRIPT_DIR/remove-duplicate-cover-images.py" index.md

if [ "$KEYPAD_MODE" = "0" ]; then
python3 <<'PY'
import json
import subprocess
from pathlib import Path

index = Path('index.md')
doc = json.loads(subprocess.run(['pandoc', str(index), '-t', 'json'], stdout=subprocess.PIPE, check=True).stdout)

def stringify_node(node):
    if isinstance(node, dict):
        t = node.get('t')
        if t == 'Str':
            return node.get('c', '')
        if t == 'Code':
            c = node.get('c')
            if isinstance(c, list) and len(c) >= 2:
                return c[1]
            return ''
        if t in ('Space', 'SoftBreak'):
            return ' '
        c = node.get('c')
        if isinstance(c, list):
            return ''.join(stringify_node(child) for child in c)
        return ''
    if isinstance(node, list):
        return ''.join(stringify_node(child) for child in node)
    if isinstance(node, str):
        return node
    return ''

def total_inline_length(inlines):
    return len(stringify_node(inlines))

def unwrap_full_strong(block):
    content = block.get('c', [])
    total = 0
    has_strong = False
    for inline in content:
        if inline['t'] == 'Strong':
            has_strong = True
            total += total_inline_length(inline['c'])
        elif inline['t'] not in ('Space', 'SoftBreak'):
            return False
    if not has_strong or total < 80:
        return False

    new_inlines = []
    for inline in content:
        if inline['t'] == 'Strong':
            new_inlines.extend(inline['c'])
        else:
            new_inlines.append(inline)
    block['c'] = new_inlines
    return True

def unwrap_leading_strong(block):
    content = block.get('c', [])
    if not content:
        return False
    first = content[0]
    if first['t'] != 'Strong':
        return False
    if total_inline_length(first['c']) < 80:
        return False
    block['c'] = first['c'] + content[1:]
    return True

changed = False
for block in doc['blocks']:
    if block['t'] == 'Para':
        if unwrap_full_strong(block) or unwrap_leading_strong(block):
            changed = True

if changed:
    new_md = subprocess.run([
        'pandoc',
        '-f', 'json',
        '-t', 'gfm',
        '--wrap', 'none'
    ],
                             input=json.dumps(doc).encode(), stdout=subprocess.PIPE,
                             check=True).stdout.decode()
    index.write_text(new_md)
PY
fi

# Remove empty headers (headers with only whitespace)
python3 "$SCRIPT_DIR/remove-empty-headers.py" index.md

# Fix disposal icon placement in Safety requirements
python3 "$SCRIPT_DIR/fix-disposal-icon.py" index.md

# Fix table spacing: ensure blank line before tables
python3 "$SCRIPT_DIR/fix-table-spacing.py" index.md

# Remove stray images that interrupt bullet lists in SP3 Features section.
# image3.png in SP3 is a product photo incorrectly placed mid-list; remove it.
# NOTE: Do NOT apply globally — other documents (e.g. iO-8 QI) use image3.png as
# a legitimate content image (step 3 wiring diagram in a numbered installation list).
case "$base" in
  SP3*|*_SP3_*)
    sed -i '' '/src="\.\/image3\.png"/d' index.md
    ;;
esac

# Replace GSM with Cellular in gate controller manuals
python3 "$SCRIPT_DIR/replace-gsm-with-cellular.py" index.md
python3 "$SCRIPT_DIR/normalize-lt-terminology.py" index.md

if [[ "$base" == FIRECOM_* ]]; then
python3 <<'PY'
from pathlib import Path
import os
import re

index = Path('index.md')
lines = index.read_text().splitlines()

def rewrite_section(lines, header_text, alt_text):
    for idx, line in enumerate(lines):
        if line.strip() == header_text.strip():
            j = idx + 1
            table_lines = []
            while j < len(lines) and lines[j].strip() == '':
                j += 1
            while j < len(lines) and lines[j].startswith('|'):
                table_lines.append(lines[j])
                j += 1
            if not table_lines:
                return

            cells = []
            for row in table_lines[2:]:
                row = row.strip()
                if row.startswith('|') and row.endswith('|'):
                    cells.append(row[1:-1].strip())

            content = ' '.join(cells)
            if not content:
                return

            parts = [part.strip(' .') for part in re.split(r'\.\s+', content) if part.strip(' .')]
            if not parts:
                return

            new_block = [lines[idx], '', f'<img src="./image4.png" alt="{alt_text}" style="width: 100%; height: auto;" />', '']
            new_block.extend(f"{i}. {part}" for i, part in enumerate(parts, 1))
            new_block.append('')

            lines[idx:j] = new_block
            return

rewrite_section(lines, '### Elements of the *FIRECOM* communicator', 'FIRECOM communicator elements')
rewrite_section(lines, '### Elementos del comunicador FIRECOM', 'Elementos del comunicador FIRECOM')
rewrite_section(lines, '### Элементы коммуникатора FIRECOM', 'Элементы коммуникатора FIRECOM')
rewrite_section(lines, '### Komunikatoriaus FIRECOM elementai', 'Komunikatoriaus FIRECOM elementai')

index.write_text('\n'.join(lines) + '\n')
PY
fi

python3 <<'PY'
from pathlib import Path
index = Path('index.md')
text = index.read_text()
updated = text.replace('\n    > ', '\n    ').replace('\n    >', '\n    ')
if updated != text:
    index.write_text(updated)
PY

# Add app store buttons (auto-detects if button images exist)
python3 "$SCRIPT_DIR/add-app-store-buttons.py" index.md

python3 <<'PY'
import re
import sys
from pathlib import Path
index = Path('index.md')
text = index.read_text()
pattern = re.compile(r'`(<[^`>]+>)`\{=html\}')
updated, count = pattern.subn(r'\1', text)
if count:
    index.write_text(updated)
    print(f"[html-cleanup] replaced {count} raw HTML spans", file=sys.stderr)
PY

# Final pass to split escaped headings that remain inside admonition lines
python3 "$SCRIPT_DIR/fix-inline-admonition-headings.py" index.md

if [ "$KEYPAD_MODE" = "1" ]; then
  python3 "$SCRIPT_DIR/rewrite_keypad_tables.py" index.md
python3 <<'PY'
from pathlib import Path
import os
import re

index = Path('index.md')
text = index.read_text()

# Normalize media paths that may still reference "media/"
text = text.replace('](media/', '](').replace('src="media/', 'src="./')
# Normalize bare image filenames to ./imageX.ext for Typora friendliness
text = re.sub(r'!\[\]\((image[0-9]+\.(?:png|jpe?g))\)', r'![](./\1)', text)
text = re.sub(r'!\[\]\((?!\./)(image[0-9]+\.(?:png|jpe?g))\)', r'![](./\1)', text)
text = re.sub(r'src="(image[0-9]+\.(?:png|jpe?g))"', r'src="./\1"', text)
# Unescape inline button images so they render (e.g., \[![](./image2.png)\] -> ![](./image2.png))
text = re.sub(r'\\\[(\!\[[^\]]*\]\([^)]+\))\\\]', r'\1', text)
# Same for inline <img> wrapped in escaped brackets
text = re.sub(r'\\\[(<img[^>]+>)\\\]', r'\1', text)

# Upscale tiny inline icons to be readable
def scale_markdown_icon(match):
    src = match.group(1)
    return f'<img src="./{src}" alt="" style="width:0.35in;height:auto" />'
text = re.sub(r'!\[\]\(\./?(image[0-9]+\.(?:png|jpe?g))\)', scale_markdown_icon, text)

def bump_img_style(match):
    width = float(match.group(1))
    height = match.group(2)
    if width < 0.25:
        width = 0.35
    if height:
        hval = float(height)
        if hval < 0.25:
            height = 0.35
        else:
            height = hval
    else:
        height = None
    style = f'width:{width:.4f}in;'
    if height:
        style += f'height:{height:.4f}in;'
    return f'style="{style}"'
text = re.sub(
    r'style="[^"]*width:([0-9\.]+)in;?[^"]*(?:height:([0-9\.]+)in;?)?[^"]*"',
    bump_img_style,
    text,
)

# Fix misinterpreted note heading
note_heading = '## For area status changing into the opposite one it is sufficient to enter User code and select the preferred area. To delete symbols or command entered, press button [].].'
if note_heading in text:
    text = text.replace(
        note_heading,
        '!!! note\nFor area status changing into the opposite one it is sufficient to enter User code and select the preferred area. To delete symbols or command entered, press button [].',
    )

# Convert MkDocs admonitions to GitHub-style alerts for markdown_callouts
text = re.sub(r'^!!!\s+note\s*\n', '> [!NOTE]\n> ', text, flags=re.MULTILINE)
text = re.sub(r'^!!!\s+warning(?:"[^"]*")?\s*\n', '> [!WARNING]\n> ', text, flags=re.MULTILINE)
# Normalize inline "Note" labels into GitHub-style alerts (multi-language)
text = re.sub(
    r'^\s*(?:>\s*)?\*\*<u>(Note|Nota|Pastaba|Примечание)\.?:?</u>\*\*\s*',
    r'> [!NOTE]\n> ',
    text,
    flags=re.MULTILINE,
)
text = re.sub(
    r'^\s*(?:>\s*)?\*\*(Note|Nota|Pastaba|Примечание)\.?:?\*\*\s*',
    r'> [!NOTE]\n> ',
    text,
    flags=re.MULTILINE,
)

def promote_underlined_heading(match):
    title = match.group(1).strip()
    lower = title.casefold()
    if (
        'stay' in lower
        or 'sleep' in lower
        or 'disarm' in lower
        or 'arm' in lower
        or 'armar' in lower
        or 'armado' in lower
        or 'įjungim' in lower
        or 'išjungim' in lower
        or 'снятие' in lower
        or 'постанов' in lower
    ):
        return f"### {title}"
    return match.group(0)

text = re.sub(
    r'^\s*\*\*<u>(.+?)</u>\s*:?\s*\*\*\s*:?\s*$',
    promote_underlined_heading,
    text,
    flags=re.MULTILINE,
)

# Demote specific headings that should be inline underlined text
text = text.replace(
    '### To send emergency message to your security service',
    '**<u>To send emergency message to your security service</u>**',
)
emergency_phrases = [
    'To send emergency message to your security service',
    'Para enviar un mensaje de emergencia a su servicio de seguridad',
    'Norėdami Jūsų apsaugos tarnybai išsiųsti pranešimą apie iškilusį pavojų',
    'Отправление экстренного сообщения охранному предприятию о возникшей опасности',
]
for phrase in emergency_phrases:
    text = re.sub(
        rf'^###\s+{re.escape(phrase)}\s*:?\s*$',
        f'**<u>{phrase}</u>**',
        text,
        flags=re.MULTILINE,
    )

lines = text.splitlines()
first_overview = None
cover_width = "600" if os.getenv("KEYPAD_MODE") else "400"
cover_block = [
    '<div style="text-align: center;">',
    f'  <img src="./image1.png" alt="" width="{cover_width}">',
    '</div>',
    '',
]

def find_cover_block(start: int, limit: int):
    for idx in range(start, limit):
        if lines[idx].strip() == '<div style="text-align: center;">':
            for j in range(idx + 1, min(idx + 8, limit)):
                if lines[j].strip() == '</div>':
                    block = lines[idx:j + 1]
                    if any('image1.png' in line for line in block):
                        return idx, j + 1
                    break
    return None

# Find first Keypad overview heading
for i, line in enumerate(lines):
    if line.strip() == '## Keypad overview':
        first_overview = i
        break

if first_overview is not None:
    # Drop cover blocks that appear before the heading
    while True:
        found = find_cover_block(0, first_overview)
        if not found:
            break
        start, end = found
        del lines[start:end]
        first_overview -= (end - start)

    # Remove any duplicate Keypad overview headings after the first one
    cleaned = []
    seen_first = False
    for line in lines:
        if line.strip() == '## Keypad overview':
            if seen_first:
                continue
            seen_first = True
        cleaned.append(line)
    lines = cleaned

    # Ensure cover image immediately after the heading
    insert_at = first_overview + 1
    if lines[insert_at:insert_at + len(cover_block)] != cover_block:
        lines[insert_at:insert_at] = [''] + cover_block

    # Remove any subsequent cover blocks
    i = insert_at + len(cover_block)
    while i < len(lines):
        found = find_cover_block(i, len(lines))
        if not found:
            break
        start, end = found
        del lines[start:end]

# Merge wrapped H2 headings (common in keypad docs)
i = 0
while i < len(lines) - 1:
    if lines[i].startswith('## ') and lines[i + 1].strip() and not lines[i + 1].startswith('#'):
        lines[i] = f"{lines[i].rstrip()} {lines[i + 1].lstrip()}"
        del lines[i + 1]
        continue
    i += 1

def strip_markup(value: str) -> str:
    value = re.sub(r'</?u>', '', value)
    value = value.replace('**', '')
    value = value.replace(':', '')
    value = re.sub(r'[()\\[\\]]', '', value)
    return re.sub(r'\\s+', ' ', value).strip()

overview_titles = {
    'keypad overview',
    'vista general del teclado',
    'klaviatūros apžvalga',
    'обзор клавиатуры',
}
disarm_keywords = ('disarm', 'desarm', 'išjungim', 'снятие')
arm_keywords = ('arming', 'armado', 'įjungim', 'постанов')
temporary_keywords = ('temporary', 'temporal', 'laikinas', 'врем')

# Normalize heading markers that include blockquote prefixes
for idx, line in enumerate(lines):
    for prefix in ('## ', '### ', '#### '):
        if line.startswith(prefix) and line[len(prefix):].lstrip().startswith('> '):
            lines[idx] = prefix + line[len(prefix):].lstrip()[2:]
            line = lines[idx]
            break

# Promote LT user/master codes line that was turned into a blockquote
for idx, line in enumerate(lines):
    if line.startswith('> '):
        title = strip_markup(line[2:]).casefold()
        if 'kodų įvedim' in title and (
            'vartotojo' in title or 'administratoriaus' in title
        ):
            lines[idx] = f"## {strip_markup(line[2:])}"

# Promote/demote headings based on keypad structure
for idx, line in enumerate(lines):
    if line.startswith('### '):
        title = strip_markup(line[4:]).casefold()
        if title in overview_titles:
            lines[idx] = f"## {strip_markup(line[4:])}"
            continue
        if any(keyword in title for keyword in arm_keywords) and any(
            keyword in title for keyword in disarm_keywords
        ):
            lines[idx] = f"## {strip_markup(line[4:])}"
            continue
        if 'bypass' in title and any(keyword in title for keyword in temporary_keywords):
            lines[idx] = f"## {strip_markup(line[4:])}"
            continue
    if line.startswith('## '):
        title = strip_markup(line[3:]).casefold()
        if any(keyword in title for keyword in disarm_keywords) and not any(
            keyword in title for keyword in arm_keywords
        ):
            lines[idx] = f"### {strip_markup(line[3:])}"
            continue
    underlined = re.match(r'^\*\*<u>(.+?)</u>\s*:?\*\*\s*:?\s*$', line.strip())
    if underlined:
        title = strip_markup(underlined.group(1)).casefold()
        if (
            'stay' in title
            or 'sleep' in title
            or any(keyword in title for keyword in disarm_keywords)
            or re.search(r'\\barm\\b', title)
            or 'arming' in title
            or 'armado' in title
        ):
            lines[idx] = f"### {strip_markup(underlined.group(1))}"

# Clean duplicated words in headings (e.g., "or or", "codes codes")
for idx, line in enumerate(lines):
    if line.startswith(('## ', '### ', '#### ')):
        cleaned = re.sub(r'\b(\w+)(\s+\1\b)+', r'\1', line, flags=re.IGNORECASE)
        cleaned = re.sub(r'\s+/\s+/\s+', ' / ', cleaned)
        lines[idx] = cleaned

# Drop duplicate H2 sections (keep first occurrence)
seen_h2 = set()
deduped = []
i = 0
while i < len(lines):
    line = lines[i]
    if line.startswith('## '):
        title = re.sub(r'\s+', ' ', line[3:].strip()).casefold()
        if title in seen_h2:
            i += 1
            while i < len(lines) and not lines[i].startswith(('## ', '# ')):
                i += 1
            continue
        seen_h2.add(title)
    deduped.append(line)
    i += 1
lines = deduped

# Convert overly long heading lines into notes (likely mis-parsed admonitions)
for idx, line in enumerate(lines):
    if line.startswith(('## ', '### ', '#### ')):
        title = line.lstrip('# ').strip()
        if len(title) > 120 or ('. ' in title and len(title) > 80):
            title = re.sub(r'(.{20,}?)\s*/\s*\1', r'\1', title, flags=re.IGNORECASE)
            lines[idx:idx + 1] = ['> [!NOTE]', f'> {title}']

# Keep only the first keypad-specific H1 title
title_keywords = ['sk-', 'keypad', 'teclad', 'klaviat', 'клавиат', 'touchpad']
primary_h1 = None
for idx, line in enumerate(lines):
    if line.startswith('# '):
        lower = line.casefold()
        if any(word in lower for word in title_keywords):
            primary_h1 = idx
            break

if primary_h1 is None:
    for idx, line in enumerate(lines):
        if line.startswith('## '):
            lower = line.casefold()
            if 'touchpad' in lower and any(word in lower for word in title_keywords):
                lines[idx] = f"# {line[3:].strip()}"
                primary_h1 = idx
                break

if primary_h1 is not None:
    lines = [line for idx, line in enumerate(lines) if not (line.startswith('# ') and idx != primary_h1)]

# Remove duplicated H1 + "Alarm system arming / disarming" block if it repeats
if lines:
    h1_line = None
    for line in lines:
        if line.startswith('# '):
            h1_line = line
            break
    if h1_line:
        h1_indices = [i for i, line in enumerate(lines) if line == h1_line]
        if len(h1_indices) > 1:
            dup_start = h1_indices[1]
            dup_end = len(lines)
            for i in range(dup_start + 1, len(lines)):
                if lines[i].startswith('## ') and lines[i] != '## Alarm system arming / disarming':
                    dup_end = i
                    break
            del lines[dup_start:dup_end]

text = '\n'.join(lines) + '\n'

# Restore missing inline icon in keypad note (if present)
if 'press button []' in text:
    if 'SK-LCD button' in text and Path('image10.png').exists():
        text = text.replace('press button [].', 'press button <img src="./image10.png" alt="" style="width:0.3500in;" />.')
        text = text.replace('press button []', 'press button <img src="./image10.png" alt="" style="width:0.3500in;" />')
    elif Path('image8.png').exists():
        text = text.replace('press button [].', 'press button <img src="./image8.png" alt="" style="width:0.3500in;" />.')
        text = text.replace('press button []', 'press button <img src="./image8.png" alt="" style="width:0.3500in;" />')

# Unescape bracket markers used for button labels
text = text.replace('\\[', '[').replace('\\]', ']')

# Remove escaped brackets around bold keypad button labels
text = re.sub(r'\\\[\*\*([^\]]+)\*\*\\\]', r'**\1**', text)
text = re.sub(r'\[\*\*([^\]]+)\*\*\]', r'**\1**', text)
# Strip brackets from common keypad button labels
text = re.sub(r'\*\*\[([A-Z0-9]{1,5})\]\*\*', r'**\1**', text)
text = re.sub(r'\[(ARM|OFF|OK|MENU|SLEEP|STAY|BYP|C|\d{1,2})\]', r'\1', text)

# Restore missing inline icon in translated button notes
if Path('image10.png').exists() and 'SK-LCD button' in text:
    text = re.sub(
        r'(?i)\b(button|bot[oó]n|mygtuką|mygtuka|кнопк[ауе])\s*\[\]',
        r'\1 <img src="./image10.png" alt="" style="width:0.3500in;" />',
        text,
    )
    text = text.replace('[]', '<img src="./image10.png" alt="" style="width:0.3500in;" />')
elif Path('image8.png').exists():
    text = re.sub(
        r'(?i)\b(button|bot[oó]n|mygtuką|mygtuka|кнопк[ауе])\s*\[\]',
        r'\1 <img src="./image8.png" alt="" style="width:0.3500in;" />',
        text,
    )
    text = text.replace('[]', '<img src="./image8.png" alt="" style="width:0.3500in;" />')
text = text.replace('command]', 'command').replace('comando]', 'comando')

# Remove duplicated fragments split by slash in notes or headings
text = re.sub(r'(.{20,}?)\s*/\s*\1', r'\1', text, flags=re.IGNORECASE)

# Clean duplicate sentences and slash separators in note lines
deduped_lines = []
for line in text.splitlines():
    if line.startswith('> ') and ' / ' in line:
        line = line.replace(' / ', ' ')
    # Remove repeated fragments within a line (e.g., duplicated sentences).
    while True:
        new_line = re.sub(r'(.{20,}?)\s+\1', r'\1', line, flags=re.IGNORECASE)
        if new_line == line:
            break
        line = new_line
    line = re.sub(r'(o el comando)(?:\s+\1)+', r'\1', line, flags=re.IGNORECASE)
    parts = re.split(r'(?<=[.!?])\s+', line)
    seen = set()
    kept = []
    for part in parts:
        key = part.casefold().strip()
        if not key:
            continue
        if key in seen:
            continue
        seen.add(key)
        kept.append(part.strip())
    if kept:
        line = ' '.join(kept)
    deduped_lines.append(line)
text = '\n'.join(deduped_lines) + '\n'

# Move keypad intro paragraph to the top as a note
keypad_words = ['keypad', 'klaviat', 'teclad', 'клавиат']
zone_words = ['zone', 'zon', 'зон']
paragraphs = []
current = []
for line in text.splitlines():
    if line.strip() == '':
        if current:
            paragraphs.append(current)
            current = []
        paragraphs.append([''])
        continue
    current.append(line)
if current:
    paragraphs.append(current)

intro_sentence = None
intro_sentences = []
for idx, para in enumerate(paragraphs):
    if not para or para == ['']:
        continue
    joined = ' '.join(para)
    lowered = joined.casefold()
    if '16' in joined and '2' in joined:
        if any(word in lowered for word in keypad_words) and any(word in lowered for word in zone_words):
            sentences = re.split(r'(?<=[.!?])\s+', joined)
            selected = []
            for sentence in sentences:
                s_lower = sentence.casefold()
                if any(word in s_lower for word in keypad_words) or any(word in s_lower for word in zone_words):
                    if any(token in s_lower for token in ['partition', 'area', 'zones', 'zon', 'зон']):
                        selected.append(sentence.strip())
            if selected:
                intro_sentences = selected
                cleaned = joined
                for sentence in selected:
                    cleaned = cleaned.replace(sentence, '').strip()
                if cleaned:
                    paragraphs[idx] = [cleaned]
                else:
                    paragraphs[idx] = []
                if any('16' in s and '2' in s for s in selected):
                    intro_sentence = ' '.join(selected)
                break
    if intro_sentence:
        break

if intro_sentence:
    note_lines = ['> [!NOTE]', '> ' + intro_sentence]
    rebuilt = []
    for para in paragraphs:
        if para == []:
            continue
        rebuilt.extend(para)
    text = '\n'.join(rebuilt).strip() + '\n'
    lines = text.splitlines()
    inserted = False
    for i in range(len(lines) - len(cover_block) + 1):
        if lines[i:i + len(cover_block)] == cover_block:
            insert_at = i + len(cover_block)
            lines[insert_at:insert_at] = [''] + note_lines + ['']
            inserted = True
            break
    if not inserted:
        for i, line in enumerate(lines):
            if line.strip() == '## Keypad overview':
                lines[i + 1:i + 1] = [''] + note_lines + ['']
                break
    text = '\n'.join(lines).strip() + '\n'

# Fix stray punctuation after keypad button sequences (e.g., **0**.).)
text = text.replace('**0**.).', '**0**).')
index.write_text(text)
PY
fi

# Final SP3 compatibility cleanup after all markdown reshaping is complete.
python3 "$SCRIPT_DIR/fix-quoted-headings.py" index.md
python3 "$SCRIPT_DIR/normalize-residual-underlines.py" index.md
python3 "$SCRIPT_DIR/inject-sp3-legacy-anchors.py" index.md

# Optimize images for web and print (max 1200px width, 85% quality)
echo "Optimizing images..."
shopt -s nullglob
for img in *.png *.jpg *.jpeg; do
  [ -f "$img" ] || continue

  # Get dimensions
  WIDTH=$(sips -g pixelWidth "$img" 2>/dev/null | grep pixelWidth | awk '{print $2}')

  # Only resize if wider than 1200px
  if [ "$WIDTH" -gt 1200 ] 2>/dev/null; then
    sips -Z 1200 "$img" >/dev/null 2>&1
  fi

  # Optimize PNGs with pngquant if available
  if [[ "$img" == *.png ]] && command -v pngquant &> /dev/null; then
    pngquant --quality=80-95 --force --ext .png "$img" >/dev/null 2>&1 || true
  fi
done
echo "Images optimized"

popd >/dev/null
echo "✅ Wrote: ${doc_dir}/index.md (images in same folder)"
