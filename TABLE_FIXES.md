# Table Conversion Fixes - October 2025

## Problem Summary

Tables in converted TRIKDIS manuals were not rendering properly in MkDocs. Three separate issues were identified and fixed.

## Issue 1: Tables in HTML Format Instead of Pipe Tables

### Symptom
Tables appeared as malformed HTML in the markdown source:
```markdown
<table>
<tbody>
<tr>
<td><strong>Parameter</strong>
<p>Network connectivity</p>
</td>
<td>DescriptionLTE / Ethernet</td>
</tr>
```

### Root Cause
The `convert-underline.lua` filter had a `Pandoc()` function that was doing round-trip markdown conversion:
```lua
function Pandoc(doc)
  local content = pandoc.write(doc, "markdown")
  content = content:gsub("%[([^%]]+)%]%{%.underline%}", "<u>%1</u>")
  return pandoc.read(content, "markdown")  -- THIS DESTROYS TABLES
end
```

This was re-parsing markdown and interpreting table headers as H1 headings, completely corrupting table structure.

### Fix
**File**: `convert-underline.lua`

Removed the `Pandoc()` function entirely. The `Span()` and `Str()` functions are sufficient for handling underline conversion.

**Result**: Tables now convert to proper pipe format from Pandoc's initial HTML output.

---

## Issue 2: Blank Lines Between Every Table Row

### Symptom
Tables had blank lines between every row, breaking the pipe table format:
```markdown
| Manufacturer | Model |

|--------------|-------|

| DSC® | PC585... |

| PARADOX® | SPECTRA... |
```

MkDocs requires continuous rows without blank lines for pipe tables to render.

### Root Cause
The `fix-table-spacing.py` script was treating EVERY line starting with `|` as a "table start" and adding blank lines before it:

```python
is_table_start = next_line.strip().startswith('|') and '|' in next_line.strip()[1:]
```

This matched both table headers AND data rows.

### Fix
**File**: `fix-table-spacing.py` (lines 22-30)

Added check to only treat as table start if current line is NOT already a table row:

```python
# Check if next line starts a NEW table (not just any table row)
is_table_row = next_line.strip().startswith('|') and '|' in next_line.strip()[1:]

# Only treat as table start if current line is NOT already a table line
current_is_table_row = current_line.strip().startswith('|')
is_table_start = is_table_row and not current_is_table_row
```

**Result**: Blank lines only added BEFORE new tables, not between rows.

---

## Issue 3: Multi-Paragraph Cell Content Split Across Lines

### Symptom
Cells with multiple paragraphs in the DOCX were split across lines in pipe tables:
```markdown
| Dual purpose terminals [IN/​OUT] | 2, can be set as either NC;​ NO;​ NC/​EOL...
Expandable with iO-8 expanders. |
```

The closing `|` appeared on the next line, breaking the table row.

### Root Cause
The `html-tables-to-pipes.py` script was not normalizing whitespace when converting cell content. Multi-paragraph cells from HTML were being preserved with newlines intact.

### Fix
**File**: `html-tables-to-pipes.py` (lines 64-75)

Added whitespace normalization when processing cells:

```python
elif tag == "th":
    self.in_th = False
    # Normalize whitespace: replace multiple spaces/newlines with single space
    cell_content = ' '.join(self.current_cell.split())
    self.headers.append(cell_content)
    self.current_cell = ""
elif tag == "td":
    self.in_td = False
    # Normalize whitespace: replace multiple spaces/newlines with single space
    cell_content = ' '.join(self.current_cell.split())
    self.current_row.append(cell_content)
    self.current_cell = ""
```

**Result**: Multi-paragraph cells joined into single line with spaces.

---

## Verification

All three fixes were tested and verified with the latest TRIKDIS manuals:

### GET Cellular Communicator
- ✅ Compatible panels table (lines 66-77): Proper pipe format, "ESPRIT E55" present
- ✅ Specifications table (lines 89-108): Proper pipe format, all modem details preserved
- ✅ No empty cells, no HTML tags

### GT Cellular Communicator
- ✅ Compatible panels table: Proper pipe format
- ✅ Specifications table (lines 91-108): Multi-paragraph "Dual purpose terminals" cell on one line
- ✅ All modem specifications preserved

### GT+ Cellular Communicator
- ✅ Compatible panels table: Proper pipe format
- ✅ Specifications table (lines 92-109): Multi-paragraph "Dual purpose terminals" cell on one line
- ✅ All modem specifications preserved

## Pipeline Order

The fixes work in this sequence during conversion:

1. **Pandoc conversion** → HTML tables with proper `<thead>` and `<tbody>`
2. **Lua filters** (including fixed `convert-underline.lua`) → Preserves table structure
3. **html-tables-to-pipes.py** → Converts HTML to pipe tables with normalized whitespace
4. **fix-table-spacing.py** → Adds blank line before new tables only

## Related Files

- `convert-single.sh` - Disabled `flatten-rowspan.lua` filter (line 51)
- `flatten-rowspan.lua` - No longer used in pipeline
- `TABLE_STRUCTURE_FIX.md` - Documents earlier table fixes
- `GITHUB_ALERTS_CONFIG.md` - MkDocs configuration for alerts

## Testing

To test table conversion:

```bash
cd /Users/local/projects/knowledgebase-conversion-pipeline

# Convert a manual
env OUT_DIR="/tmp/test-tables" ./convert-single.sh "path/to/manual.docx"

# Check table format
grep -A 10 "| Parameter |" /tmp/test-tables/*/index.md

# Verify no HTML tables remain
grep "<table>" /tmp/test-tables/*/index.md  # Should return nothing
```

---

## Issue 4: Repeated Manufacturer Names in Compatible Panels Table

### Symptom
Manufacturer names like PARADOX® and Texecom® were repeated on every row in the compatible control panels table:

```markdown
| Manufacturer | Model |
|--------------|-------|
| PARADOX® | SPECTRA SP4000, SP5500... |
| PARADOX® | MAGELLAN MG5000, MG5050... |
| PARADOX® | DIGIPLEX EVO48, EVO192... |
| PARADOX® | SPECTRA 1727, 1728, 1738 |
| PARADOX® | ESPRIT E55 |
```

In the original PDF, PARADOX® appears once with 5 model rows below it using rowspan.

### Root Cause
The `flatten_rowspan_html()` function was duplicating the manufacturer cell content across all spanned rows instead of merging the model content with `<br>` tags.

### Fix
**File**: `html-tables-to-pipes.py` (lines 178-256)

Rewrote `flatten_rowspan_html()` to:
1. Identify cells with rowspan attribute
2. Collect content from subsequent rows (the model column)
3. Merge models with `<br>` separator
4. Place merged content in second column of first row
5. Skip rendering the merged rows

**Also updated** (line 46): Changed `<br>` tag handling from converting to " / " to preserving `<br>`:
```python
# Keep <br> tags for rowspan merging
if self.in_th or self.in_td:
    self.current_cell += "<br>"
```

**Result**: Manufacturer appears once with all models joined by `<br>`:

```markdown
| Manufacturer | Model |
|--------------|-------|
| PARADOX® | SPECTRA SP4000, SP5500...<br>MAGELLAN MG5000, MG5050...<br>DIGIPLEX EVO48, EVO192...<br>SPECTRA 1727, 1728, 1738<br>ESPRIT E55 |
```

---

## Date
October 9, 2025

---

## Issue 5: Underlines Lost in Table Cells

### Symptom
Underlined text in table cells (indicating directly-controlled control panels) was lost during conversion to pipe tables.

In the PDF, models like "PC585", "SPECTRA SP4000", etc. are underlined to indicate they support direct control.

### Root Cause
Pandoc's GFM (GitHub Flavored Markdown) writer **strips HTML tags from table cells** when creating pipe tables. Even though `convert-underline.lua` converts `Underline` AST elements to `<u>` tags, these get removed when Pandoc outputs pipe tables.

### Fix
**Files**: `convert-underline.lua` and `convert-single.sh` (line 199)

Implemented a **marker-based approach** that works for any underlined text in any table:

1. **Lua filter** (convert-underline.lua): Convert `Underline` elements to special Unicode markers that survive GFM conversion:
   ```lua
   function Underline(elem)
     local content = pandoc.utils.stringify(elem.content)
     return pandoc.Str("⟪U⟫" .. content .. "⟪/U⟫")
   end
   ```

2. **Post-processing** (convert-single.sh): Convert markers to HTML after pipe tables are created:
   ```bash
   sed -i '' 's/⟪U⟫/<u>/g; s/⟪\/U⟫/<\/u>/g' index.md
   ```

**Result**: All underlines preserved exactly as they appear in the original DOCX:

```markdown
| DSC® | <u>PC585</u>, <u>PC1404</u>, <u>PC1565</u>... |
| PARADOX® | <u>SPECTRA SP4000</u>, <u>SP5500</u>...<br><u>MAGELLAN MG5000</u>... |
```

**Benefits:**
- Generic solution works for ANY underlined text in ANY table
- No hardcoded patterns needed
- Works with rowspan merging (models with `<br>` tags)
- Preserves exact underlining from original document

---

## Date
October 9, 2025

---

## Issue 6: Underline Tag Preservation in HTML Table Parser

### Symptom
After implementing the marker-based underline preservation (Issue 5), underline tags were not being properly preserved during HTML table parsing.

### Root Cause
The `html-tables-to-pipes.py` parser was capturing all inner HTML tags generically without special handling for `<u>` tags used for underlining.

### Fix
**File**: `html-tables-to-pipes.py` (lines 140-146)

Added special handling for `<u>` tags to ensure they're preserved correctly:

```python
def handle_starttag(self, tag, attrs):
    # ... existing code ...
    elif self.in_cell:
        # Preserve <u> tags for underlining
        if tag == 'u':
            self.current_cell['content_parts'].append('<u>')
        else:
            # Capture other inner HTML tags, preserve <br> tags
            attrs_str = ' '.join(f'{k}="{v}"' for k, v in attrs) if attrs else ''
            tag_str = f'<{tag}' + (f' {attrs_str}' if attrs_str else '') + '>'
            self.current_cell['content_parts'].append(tag_str)
```

**Result**: Underline tags are now properly preserved during HTML table parsing, ensuring the complete end-to-end underline preservation pipeline works correctly.

---

## Date
October 9, 2025

## Commits
- `2815350` - Fix table structure issues in pipe table conversion
- `48ddb21` - Merge rowspan cells with <br> tags instead of duplicating content
- `faf7512` - Preserve underlines in tables using marker approach
- `55187f4` - Fix admonition blockquote wrapping in note sections
- `65d202a` - Preserve <u> tags during HTML table parsing for underline support
