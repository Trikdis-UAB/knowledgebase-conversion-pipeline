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

# Ensure filters exist
for f in strip-cover.lua strip-toc.lua promote-strong-top.lua demote-extra-h1.lua fix-numbered-heading-levels.lua normalize-headings.lua move-first-image-to-description.lua split-inline-images.lua reposition-sentence-splitting-images.lua convert-image-sizes.lua softwrap-tokens.lua clean-table-pipes.lua mark-two-col.lua convert-underline.lua remove-unwanted-blockquotes.lua maintain-list-continuity.lua strip-classes.lua fix-typography.lua bold-list-titles.lua fix-crossrefs.lua clean-html-blocks.lua unwrap-table-blockquotes.lua remove-standalone-asterisks.lua fix-rowspan-headers.lua flatten-instruction-tables.lua; do
  [ -f "$FILTER_DIR/$f" ] || { echo "Missing $f"; exit 1; }
done
# Check the filters in filters subdirectory
[ -f "$FILTER_DIR/convert-legend-tables-ordered-lists.lua" ] || { echo "Missing lua-filters/convert-legend-tables-ordered-lists.lua"; exit 1; }
[ -f "$FILTER_DIR/flatten-two-cell-tables.lua" ] || { echo "Missing lua-filters/flatten-two-cell-tables.lua"; exit 1; }

mkdir -p "$doc_dir"
pushd "$doc_dir" >/dev/null

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
  --lua-filter="$FILTER_DIR/collapse-spacer-columns.lua" \
  --lua-filter="$FILTER_DIR/convert-keypad-layout.lua" \
  --lua-filter="$FILTER_DIR/promote-keypad-headings.lua" \
  --lua-filter="$FILTER_DIR/convert-legend-tables-ordered-lists.lua" \
  --lua-filter="$FILTER_DIR/flatten-two-cell-tables.lua" \
  --lua-filter="$FILTER_DIR/flatten-instruction-tables.lua" \
  --lua-filter="$FILTER_DIR/flatten-layout-tables.lua" \
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
  --lua-filter="$FILTER_DIR/scale-inline-icons.lua" \
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

cp index.md /tmp/pre-keypad.md

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

case "$base" in
  "SK-LCD button"*|"SK-LCD TouchPad"*|"SK-LED button"*|"SK-LED TouchPad"*|"FLEXI_SK_"*)
    perl -0pi -e 's#<div style="text-align: center;">\s*\n\s*<img src="\./image1\.png"[^>]*width="400"[^>]*>\s*\n</div>\n\n##' index.md
    ;;
esac

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

python3 <<'PY'
import json
import subprocess
import sys
from subprocess import TimeoutExpired
from pathlib import Path

index = Path('index.md')
try:
    doc_json = subprocess.run(
        ['pandoc', str(index), '-t', 'json'],
        stdout=subprocess.PIPE,
        check=True,
        timeout=30,
    ).stdout
except TimeoutExpired:
    print("[unwrap-strong] skipped: pandoc json conversion timed out", file=sys.stderr)
    sys.exit(0)

doc = json.loads(doc_json)

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
    new_md = subprocess.run(
        ['pandoc', '-f', 'json', '-t', 'gfm', '--wrap', 'none'],
        input=json.dumps(doc).encode(),
        stdout=subprocess.PIPE,
        check=True,
    ).stdout.decode()
    index.write_text(new_md)
PY

# Remove empty headers (headers with only whitespace)
python3 "$SCRIPT_DIR/remove-empty-headers.py" index.md

# Fix disposal icon placement in Safety requirements
python3 "$SCRIPT_DIR/fix-disposal-icon.py" index.md

# Fix table spacing: ensure blank line before tables
python3 "$SCRIPT_DIR/fix-table-spacing.py" index.md

# Remove stray images that interrupt bullet lists (e.g., image3.png in SP3 Features section)
# These are typically product images incorrectly placed in the middle of feature lists
# Runs after all Python post-processors to ensure it's not re-added
sed -i '' '/^[[:space:]]*<img src="\.\/image3\.png"/d' index.md

# Replace GSM with Cellular in gate controller manuals
python3 "$SCRIPT_DIR/replace-gsm-with-cellular.py" index.md
python3 "$SCRIPT_DIR/normalize-lt-terminology.py" index.md

if [[ "$base" == FIRECOM_* ]]; then
python3 <<'PY'
from pathlib import Path
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

python3 "$SCRIPT_DIR/rewrite_keypad_tables.py" index.md

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

# Final keypad table rewrite (safety net in case upstream steps reintroduced JSON blobs)
python3 "$SCRIPT_DIR/rewrite_keypad_tables.py" index.md

python3 <<'PY'
from pathlib import Path
index = Path('index.md')
text = index.read_text()

# Normalize media paths that may still reference "media/"
text = text.replace('](media/', '](').replace('src="media/', 'src="./')
# Normalize bare image filenames to ./imageX.ext for Typora friendliness
import re
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

# Render admonitions in a Typora-friendly way (blockquote with bold label)
text = re.sub(
    r'^!!!\s+note\s*\n([^\n]+)',
    r'> **Note.** \1',
    text,
    flags=re.MULTILINE,
)
text = re.sub(
    r'^!!!\s+warning(?:"[^"]*")?\s*\n([^\n]+)',
    r'> **Warning.** \1',
    text,
    flags=re.MULTILINE,
)

# Demote specific headings that should be inline underlined text
text = text.replace(
    '### To send emergency message to your security service',
    '**<u>To send emergency message to your security service</u>**',
)

lines = text.splitlines()
first_overview = None
cover_block = [
    '<div style="text-align: center;">',
    '  <img src="./image1.png" alt="" width="400">',
    '</div>',
    '',
]

# Find first Keypad overview heading
for i, line in enumerate(lines):
    if line.strip() == '## Keypad overview':
        first_overview = i
        break

if first_overview is not None:
    # Drop cover blocks that appear before the heading
    i = 0
    while i < first_overview:
        if lines[i:i + len(cover_block)] == cover_block:
            del lines[i:i + len(cover_block)]
            first_overview -= len(cover_block)
            continue
        i += 1

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
        if lines[i:i + len(cover_block)] == cover_block:
            del lines[i:i + len(cover_block)]
            continue
        i += 1

text = '\n'.join(lines) + '\n'
index.write_text(text)
PY

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
