# Grid Tables vs Pipe Tables - Decision Log

**Date:** October 8, 2025
**Decision:** Use pipe tables with `<br>` tags for multi-line content, NOT grid tables

## The Problem

Pandoc-generated grid tables have multi-line cells that are essential for complex technical documentation (DTMF commands, SMS instructions, etc.). These tables look like:

```
+---------------+--------------------+----------------------------------------+
| DTMF code      | Function            | Description                             |
+===============+====================+========================================+
| OUTPUT*STATE#  | Output control      | Output control command (turn on/turn off)|
|                |                     |                                         |
|                |                     | OUTPUT – number of the controlled output.|
|                |                     |                                         |
|                |                     | STATE – control command:                |
|                |                     | 0 – turn off output                     |
|                |                     | 1 – turn on output                      |
+---------------+--------------------+----------------------------------------+
```

## Why Grid Tables Don't Work in MkDocs

### Technical Reasons

1. **MkDocs uses Python-Markdown** - NOT Pandoc for rendering
2. **Python-Markdown extensions don't support Pandoc grid tables**
3. **No way to replace Python-Markdown with Pandoc** in MkDocs core

### Extensions Tested

1. **markdown-grid-tables (0.6.0)**
   - Status: Latest version on PyPI
   - Problem: Renders as `<pre class=grid-table-error>`
   - Reason: Can't parse Pandoc's flexible grid table format

2. **markdown-grids (1.0.0)**
   - Status: Alternative extension
   - Problem: "One or more table lines differ in length"
   - Reason: Requires all grid table lines to be EXACTLY the same length
   - Pandoc allows content to overflow beyond column boundaries

### Fundamental Incompatibility

- **Pandoc grid tables**: Lines can be different lengths (flexible)
- **Python-Markdown extensions**: Lines must be EXACTLY the same length (strict)

This is an architectural incompatibility, not a bug we can fix.

## The Solution

**Use standard pipe tables with `<br>` tags for line breaks:**

```markdown
| DTMF code | Function | Description |
|-----------|----------|-------------|
| OUTPUT*STATE# | Output control | Output control command (turn on/turn off)<br><br>OUTPUT – number of the controlled output<br><br>STATE – control command:<br>0 – turn off output<br>1 – turn on output<br>2 – turn off for pulse time<br>3 – turn on for pulse time |
```

### Why This Works

✅ **Compatible** - Works perfectly with MkDocs Python-Markdown
✅ **Readable** - Source remains human-readable (better than HTML tables)
✅ **Renders well** - Displays properly in all browsers
✅ **Maintainable** - Standard markdown format
✅ **No special extensions** - Uses built-in HTML support in markdown

### Best Practices

- Use double `<br><br>` for paragraph breaks
- Use single `<br>` for line breaks
- Keep source as readable as possible
- Test in MkDocs preview before publishing

## Alternatives Considered and Rejected

### ❌ HTML Tables
```html
<table>
  <tr><td>...</td></tr>
</table>
```
**Rejected:** Not human-readable in markdown source

### ❌ Grid Tables
```
+---+---+
| A | B |
+===+===+
```
**Rejected:** Incompatible with MkDocs Python-Markdown processor

### ❌ Normalize Grid Tables
Fix line lengths to all be exactly the same
**Rejected:** Too tedious, fragile, hard to maintain

## Documentation Updated

- ✅ `/Users/local/projects/knowledgebase-conversion-pipeline/WRITERS_GUIDE.md` - Added multi-line table section
- ✅ `/Users/local/projects/knowledgebase-conversion-pipeline/CLAUDE.md` - Updated critical rules
- ✅ `/Users/local/projects/trikdis-docs/manuals/mkdocs.yml` - Reverted to standard tables
- ✅ `/Users/local/projects/trikdis-docs/manuals/requirements.txt` - Removed markdown-grids

## Next Steps

1. Update conversion pipeline to convert grid tables to pipe tables with `<br>` tags
2. Reconvert GATOR manual with updated pipeline
3. Apply same fix to other manuals with grid tables (SP3, GET, GT, GT+)

## References

- MkDocs Discussion: https://github.com/mkdocs/mkdocs/discussions/2784
- markdown-grid-tables: https://pypi.org/project/markdown-grid-tables/
- markdown-grids: https://github.com/mjayfrancis/markdown-grids
- Pandoc Grid Tables: https://pandoc.org/MANUAL.html#tables

---

**Lesson Learned:** Always check if your documentation generator uses Pandoc or Python-Markdown BEFORE choosing a table format. They are NOT compatible.
