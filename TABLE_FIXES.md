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

## Date
October 9, 2025

## Commit
`2815350` - Fix table structure issues in pipe table conversion
