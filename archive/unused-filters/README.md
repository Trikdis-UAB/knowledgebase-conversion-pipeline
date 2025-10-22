# Archived Filters

This directory contains unused Lua filters that were replaced by newer versions or experimental filters that were never integrated into the pipeline.

## Archived on October 22, 2025

### Replaced Filters (Old Versions)
These filters were replaced by improved versions:

1. **append-warranty.lua** → Replaced by `relocate-warranty.lua`
   - Old approach to warranty section handling
   - New version supports multiple consecutive sections

2. **preserve-warranty.lua** → Replaced by `relocate-warranty.lua`
   - Early version of warranty preservation
   - Superseded by complete relocation solution

3. **clean-table-blockquotes.lua** → Replaced by `unwrap-table-blockquotes.lua`
   - Old table blockquote cleaner
   - New version has better AST handling

4. **fix-rowspan-tables.lua** → Replaced by `fix-rowspan-headers.lua`
   - Old rowspan fixing approach
   - New version handles malformed headers more robustly

5. **flatten-numbered-list-tables.lua** → Functionality merged into other filters
   - Old approach to flattening numbered list tables
   - Functionality now handled by multiple specialized filters

6. **flatten-rowspan.lua** → Replaced by `fix-rowspan-headers.lua`
   - Early rowspan flattening attempt
   - New version provides cleaner output

7. **flatten-two-cell-tables.lua** → Replaced by `filters/flatten-two-cell-tables.lua`
   - Duplicate filter (moved to filters/ subdirectory)
   - The version in filters/ is used

8. **unwrap-post-image-blockquotes.lua** → Functionality merged
   - Experimental blockquote unwrapping
   - Functionality absorbed into `remove-unwanted-blockquotes.lua`

### Experimental Filters (Never Used)
These filters were experimental and never integrated:

9. **extract-table-images.lua** (4664 bytes)
   - Experimental: Extract images from table cells
   - Never integrated into pipeline

10. **force-markdown-tables.lua** (1988 bytes)
    - Experimental: Force all tables to markdown format
    - Never integrated into pipeline

## Why Archive Instead of Delete?

These filters are archived rather than deleted because they:
- Document the evolution of the conversion pipeline
- May contain useful algorithms for future reference
- Serve as examples of approaches that didn't work out
- Can be restored if needed for debugging legacy conversions

## Active Pipeline

The active conversion pipeline uses **35 Lua filters** located in:
- Main directory: 33 filters
- `filters/` subdirectory: 2 filters

Plus **8 Python post-processors** for a total of **43 active filters**.

For the current filter list, see the main README.md.
