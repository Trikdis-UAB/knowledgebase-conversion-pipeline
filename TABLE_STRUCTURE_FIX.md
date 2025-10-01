# Table Structure Fix Documentation

## Overview
The `fix_table_structure.py` script automatically fixes table structure issues during DOCX to Markdown conversion to ensure proper display in MkDocs.

## Problems Solved

### 1. H1 Tags Inside Table Cells
**Problem**: Pandoc converts some table headers as `<td><h1><strong>Header</strong></h1>`
**Solution**: Converts to proper `<th><strong>Header</strong></th>`

### 2. Malformed Rowspan Structures
**Problem**: Mixed opening/closing tags like:
```html
<th rowspan="2"><strong>Parameter</strong></th>
<p>Connection to the control panel</p>
</td>  <!-- Wrong closing tag -->
```
**Solution**: Creates proper table structure:
```html
<th><strong>Parameter</strong></th>
<th><strong>Description</strong></th>
</tr>
<tr>
<td><p>Connection to the control panel</p></td>
<td><p>Serial bus, Keypad bus or TIP RING</p></td>
```

### 3. Empty Table Rows
**Problem**: `<tr></tr>` and `<tr><td></td></tr>` causing layout issues
**Solution**: Removes empty rows entirely

### 4. Visual Display Issues
**Problem**: Tables showing vertical text in first row instead of horizontal headers
**Solution**: Proper header/data separation with correct HTML semantics

## Integration

### Automatic Application
The fix is integrated into `convert-single.sh` at line 95:
```bash
# Fix table structure issues (H1 in cells, empty rows, malformed headers)
python3 "$SCRIPT_DIR/fix_table_structure.py" index.md
```

### Pipeline Order
Applied after Pandoc conversion but before other cleanup scripts:
1. Pandoc DOCX → Markdown conversion
2. Various Lua filters
3. **Table structure fix** ← Applied here
4. Admonition fixes
5. Image fixes
6. List continuity fixes

## Technical Details

### Pattern Detection
The script detects specific malformed patterns:
- `<th rowspan="2"><strong>([^<]+)</strong></th>\s*<p>([^<]*)</p>\s*</td>`
- `<td><h1[^>]*><strong>([^<]+)</strong></h1>`
- Empty `<tr>` elements

### Fix Algorithm
1. **Header Extraction**: Extracts header names and first row content
2. **Structure Rebuild**: Creates proper `<thead>` with headers
3. **Data Separation**: Places content in proper `<tbody>` data cells
4. **Cleanup**: Removes malformed original structure

### Supported Table Types
- Two-column tables (Parameter/Description, Terminal/Description)
- Multi-column tables with proper headers
- Tables with rowspan attributes (converts to standard structure)
- Mixed content tables with paragraphs and formatted text

## Files Modified

### Main Script
- `fix_table_structure.py` - Core table fixing logic

### Pipeline Integration
- `convert-single.sh` - Calls the script automatically

### Documentation
- `TABLE_STRUCTURE_FIX.md` - This documentation
- `GITHUB_ALERTS_CONFIG.md` - Related MkDocs configuration

## Testing

### Verification Steps
1. Convert DOCX with problematic tables
2. Check that tables display with horizontal headers
3. Verify all content is preserved
4. Confirm proper HTML structure

### Common Issues Fixed
- ✅ Vertical text in table headers → Horizontal headers
- ✅ H1 tags in cells → Proper TH tags
- ✅ Malformed rowspan → Clean table structure
- ✅ Empty rows → Removed automatically
- ✅ Mixed opening/closing tags → Consistent HTML

## Future Maintenance

### Adding New Fix Patterns
To handle new table structure issues:
1. Add pattern detection in `fix_table_structure.py`
2. Implement fix logic following existing patterns
3. Test with problematic documents
4. Update this documentation

### Debugging
If tables still display incorrectly:
1. Check conversion pipeline logs
2. Examine raw HTML output
3. Test fix script manually: `python3 fix_table_structure.py file.md`
4. Compare before/after table structure

## Result
Every DOCX conversion now automatically produces properly structured tables that display correctly in MkDocs without manual intervention.