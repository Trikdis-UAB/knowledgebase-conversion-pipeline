# CLAUDE.md - Knowledgebase Conversion Pipeline Context

**Location:** `/Users/local/projects/knowledgebase-conversion-pipeline/CLAUDE.md`

## Auto-loaded Context
@./README.md
@./FILTER_USAGE.md
@./GITHUB_ALERTS_CONFIG.md
@./TABLE_STRUCTURE_FIX.md
@./WRITERS_GUIDE.md

## What is this project?

Convert TRIKDIS product manuals from .docx to clean Markdown for MkDocs and Typora. Automated pipeline with 8 Lua filters for heading normalization, admonition conversion, and image handling.

## Quick Reference

### Convert Single File
```bash
cd /Users/local/projects/knowledgebase-conversion-pipeline
./convert-single.sh "path/to/manual.docx"
```

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
- All 8 Lua filters present
- Check with: `./check-requirements.sh`

## File Locations

### Local Projects
- **This project**: `/Users/local/projects/knowledgebase-conversion-pipeline/`
- **Publishing target**: `/Users/local/projects/trikdis-docs/manuals/`

### Source Files
- **External drive**: `/Volumes/TRIKDIS/PRODUKTAI/`
- **Local storage**: `docx manuals/` subdirectory

## Processing Pipeline

### Lua Filters (Applied in Order)
1. `strip-cover.lua` - Remove cover pages
2. `strip-toc.lua` - Remove Table of Contents
3. `promote-strong-top.lua` - Promote bold lines to H2
4. `table-to-admonition.lua` - Convert callout tables
5. `normalize-headings.lua` - Fix heading levels (1.1→H3, 1.1.1→H4)
6. `strip-classes.lua` - Remove Word styling
7. `fix-typography.lua` - Clean apostrophes/quotes
8. `fix-crossrefs.lua` - Fix broken references

### What Gets Fixed
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
✅ 8 Lua filters working
✅ GitHub Pages deployment documented
✅ MkDocs Material compatibility confirmed
✅ Automatic table structure fixes
✅ GitHub alerts support
✅ Numbered list continuity

---

*Last updated: October 2025*
