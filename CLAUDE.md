# CLAUDE.md - Knowledgebase Conversion Pipeline Context

**Location:** `/Users/local/projects/knowledgebase-conversion-pipeline/CLAUDE.md`

## Auto-loaded Context
@./README.md
@./FILTER_USAGE.md
@./GITHUB_ALERTS_CONFIG.md
@./TABLE_STRUCTURE_FIX.md
@./WRITERS_GUIDE.md

## MCP Tools Available

### Pandoc MCP Server
**Status**: ✅ Configured and available via uvx
**Purpose**: Document format conversion, AST inspection, testing Pandoc transformations

**Tool**: `convert-contents`
- Convert between formats (DOCX, Markdown, HTML, PDF, LaTeX, RST, EPUB, ODT, IPYNB, TXT)
- Test Pandoc filter behavior
- Inspect document AST structure
- Validate conversion settings

**Usage**:
```bash
# Check AST structure of a DOCX file
uvx mcp-pandoc convert-contents --input-file "file.docx" --output-format native

# Test GFM table conversion
uvx mcp-pandoc convert-contents --input-file "file.docx" --output-format gfm

# Test with specific Pandoc flags
uvx mcp-pandoc convert-contents --input-file "file.docx" --output-format markdown --extra-args "--wrap=none"
```

**Configuration**: Uses `uvx mcp-pandoc` (installed via Homebrew uv package)

## What is this project?

Convert TRIKDIS product manuals from .docx to clean Markdown for MkDocs and Typora. Automated pipeline with 21 Lua filters for comprehensive document cleanup and normalization.

## Quick Reference

### Convert Single File
```bash
cd /Users/local/projects/knowledgebase-conversion-pipeline
./convert-single.sh "path/to/manual.docx"
```

### Preview Converted Manuals
```bash
./preview.sh
```
- Syncs latest mkdocs.yml from trikdis-docs
- Serves on http://127.0.0.1:8001
- Shows exactly how manuals will look when published

### Output Location
```
docs/manuals/[Manual Name]/
├── index.md       # Converted content
└── *.png          # All images in same folder
```

### Common Source Paths
- External drive: `/Volumes/TRIKDIS/PRODUKTAI/`
- Local docx: `docx manuals/`

## Key Details

### Output Structure
- **NOT** `output/` directory
- **YES** `docs/manuals/[Manual Name]/` directory
- Each manual gets its own folder with `index.md` + images

### Publishing Workflow
1. Convert DOCX in this project
2. Copy output to `/Users/local/projects/trikdis-docs/manuals/docs/manual/`
3. Update mkdocs.yml if needed
4. Git commit and push (auto-deploys to https://docs.trikdis.com)

### Prerequisites
- Pandoc installed via Homebrew
- All 23 Lua filters present
- Check with: `./check-requirements.sh`

### Batch Conversion
- `convert-batch.sh` calls `convert-single.sh` for each file
- Ensures identical output quality and consistency
- No duplication of conversion logic

## File Locations

### Local Projects
- **This project**: `/Users/local/projects/knowledgebase-conversion-pipeline/`
- **Publishing target**: `/Users/local/projects/trikdis-docs/manuals/`

### Source Files
- **External drive**: `/Volumes/TRIKDIS/PRODUKTAI/`
- **Local storage**: `docx manuals/` subdirectory

## Processing Pipeline

### Lua Filters (Applied in Order)
1. `strip-cover.lua` - Remove cover pages (preserve product name for title generation)
2. `strip-toc.lua` - Remove Table of Contents
3. `promote-strong-top.lua` - Extract product name and create H1 title (e.g., "GT+ Cellular Communicator")
4. `flatten-two-cell-tables.lua` - Flatten simple tables
5. `unwrap-table-blockquotes.lua` - Remove blockquote wrappers from table cells
6. `fix-rowspan-headers.lua` - Fix malformed rowspan table headers (splits header from data)
7. `normalize-headings.lua` - Fix heading levels (1.1→H3, 1.1.1→H4)
8. `remove-empty-table-columns.lua` - Remove empty separator columns
9. `remove-standalone-asterisks.lua` - Remove `****` markers outside tables
10. `strip-classes.lua` - Remove Word styling
11. `fix-typography.lua` - Clean apostrophes/quotes
12. `fix-crossrefs.lua` - Fix broken references
...and 11 more filters (23 total)

### What Gets Fixed
- **Automatic title extraction**: Product name from DOCX → H1 title (e.g., "Cellular communicator GT+" → "# GT+ Cellular Communicator")
- **Product image formatting**: Centered with width="400" after H1 title
- **Table structure**: Malformed rowspan headers fixed, empty columns removed
- **Typography**: Escaped quotes (`\"` → `"`), escaped apostrophes (`\'` → `'`)
- **Clean markers**: Standalone `****` removed (preserved in tables)
- Heading levels normalized (1.1→H3, 1.1.1→H4)
- Note/Warning/Tip tables → MkDocs admonitions
- Images extracted to same folder as index.md
- Word artifacts removed (cover pages, ToC, styling)
- Cross-references fixed ("Error! Reference..." → "see the referenced section")

## Important Rules

1. **Always read README.md first** before making assumptions
2. **Output goes to `docs/manuals/`** not `output/`
3. **Each manual gets its own folder** with `index.md`
4. **Images go in same folder** as index.md (not media/ subdirectory)
5. **Source files unchanged** - all fixes happen during conversion

## Development Philosophy
- Manual first, automate pain points
- Never modify source .docx files
- All normalization happens during conversion
- Output ready for both Typora and MkDocs

## Additional Documentation

- **FILTER_USAGE.md** - Numbered list continuity and heading numbering systems
- **GITHUB_ALERTS_CONFIG.md** - GitHub-style alerts (`> [!NOTE]`) configuration
- **TABLE_STRUCTURE_FIX.md** - Automatic table structure fixes (H1 in cells, rowspan, etc.)
- **WRITERS_GUIDE.md** - Complete manual writing guide for content creators
- **test-input.md / test-output.md** - Test files for validation

## Status
✅ Production ready
✅ Automatic product title extraction from DOCX cover pages
✅ Product image formatting (centered, width="400")
✅ 23 Lua filters working (added 4 new table/typography filters)
✅ Rowspan header fixes at AST level
✅ Escaped quotes and apostrophes cleaned
✅ Standalone asterisks removal
✅ Empty table columns removed
✅ Batch script refactored for consistency
✅ GitHub Pages deployment documented
✅ MkDocs Material compatibility confirmed
✅ Automatic table structure fixes
✅ GitHub alerts support
✅ Numbered list continuity
✅ Centered H1 titles (CSS)

---

*Last updated: October 2025*
