# Knowledgebase Conversion Pipeline — DOCX → Markdown (Pandoc)

## Purpose

Convert product manuals from **.docx** to clean **Markdown** with correct heading levels and extracted images, ready for **MkDocs** and **Typora**. Automated pipeline with 24 Lua filters plus Python post-processing. Source files remain unchanged; all normalization happens during conversion.

---

## Prerequisites

* **Pandoc** installed via Homebrew:
  ```bash
  brew install pandoc
  ```
* All Lua filters included in this project (24 filters total)

---

## What the Pipeline Does

### Conversion Features
* **Automatic title extraction**: Extracts product name from DOCX cover page and creates proper H1 title (e.g., "GT+ Cellular Communicator")
* **Product image formatting**: Centers first product image with consistent width (400px) after H1 title
* **Folder structure**: Each manual gets its own folder with `index.md` + images in the same folder
* **Clean output**: Removes Word cover pages and Table of Contents (preserves product name for title generation)
* **Heading normalization**: Promotes `1.1 Title` → H3, `1.1.1 Title` → H4 (keeps numbers in text)
* **Table conversion**: Converts to pipe tables or HTML for MkDocs compatibility
* **Admonitions**: Converts Note/Warning/Tip tables to MkDocs admonitions
* **Callouts**: Normalizes GitHub-style `[!NOTE]` blockquotes into MkDocs/Typora-friendly admonitions
* **Typography fixes**: Cleans up backticks, broken cross-references, escaped quotes, and Word artifacts
* **Table structure fixes**: Corrects malformed rowspan headers and ensures proper thead/tbody separation
* **Image optimization**: Extracts and places images in the same folder as index.md
* **Stable image URLs**: Forces `./image.png` paths so assets render even when served without trailing slashes

### Lua Filters (Applied in Order)
The pipeline applies 24 specialized filters to clean and normalize Word documents:

1. **strip-cover.lua**: Removes cover page content but preserves product name (e.g., "Cellular communicator GT+") for title generation
2. **strip-toc.lua**: Removes Word's Table of Contents sections
3. **promote-strong-top.lua**: Extracts product name from bold text and creates H1 title in format "[MODEL] Cellular Communicator"
4. **flatten-two-cell-tables.lua**: Flattens simple two-cell tables (single row)
5. **flatten-instruction-tables.lua**: Flattens multi-row instruction tables (text + image per row)
6. **unwrap-table-blockquotes.lua**: Removes blockquote wrappers from table cells
7. **fix-rowspan-headers.lua**: Fixes malformed rowspan table headers by splitting header from data
8. **normalize-headings.lua**: Promotes multi-level numbers (1.1, 1.1.1) to proper heading levels
9. **strip-manual-heading-numbers.lua**: Removes manual heading numbers for clean output
10. **move-first-image-to-description.lua**: Positions first image properly
11. **split-inline-images.lua**: Separates inline images for proper display
12. **convert-image-sizes.lua**: Converts image sizes to HTML with CSS
13. **softwrap-tokens.lua**: Handles text wrapping
14. **remove-empty-table-columns.lua**: Removes empty separator columns from tables
15. **clean-table-pipes.lua**: Fixes table pipe characters
16. **mark-two-col.lua**: Marks two-column tables for processing
17. **convert-underline.lua**: Converts underline formatting
18. **remove-unwanted-blockquotes.lua**: Removes spurious blockquotes
19. **maintain-list-continuity.lua**: Ensures numbered lists continue correctly across interruptions
20. **strip-classes.lua**: Removes Word styling classes like `{.underline}`
21. **fix-typography.lua**: Converts backticks to proper apostrophes
22. **fix-crossrefs.lua**: Replaces "Error! Reference source not found" with "see the referenced section"
23. **remove-standalone-asterisks.lua**: Removes standalone `****` markers while preserving them in tables
24. **clean-html-blocks.lua**: Cleans HTML block structures

---

## Quick Start

1. **Check requirements**: `./check-requirements.sh`
2. **Convert single file**: `./convert-single.sh "filename.docx"`
3. **Preview locally**: `./preview.sh` (serves on http://127.0.0.1:8001)
4. **Convert all files**: `./convert-batch.sh`

---

## Single-file Conversion

```bash
./convert-single.sh "docx manuals/GT UM_ENG_2024 08 08-.docx"
```

This creates:
- `docs/manuals/GT UM_ENG_2024 08 08-/index.md` 
- `docs/manuals/GT UM_ENG_2024 08 08-/*.png` (all images in same folder)

Perfect for:
- **Typora**: Open the folder directly, images display inline
- **MkDocs**: Reference as `manuals/GT UM_ENG_2024 08 08-/index.md`

---

## Local Preview

Preview converted manuals exactly as they will appear when published:

```bash
./preview.sh
```

This script:
- Syncs latest `mkdocs.yml` and configuration from `/Users/local/projects/trikdis-docs/manuals/`
- Copies stylesheets, javascripts, and images
- Serves on http://127.0.0.1:8001 (different port than trikdis-docs)
- Ensures preview matches production exactly

**No configuration duplication** - always uses the latest production config.

---

## Batch Conversion

```bash
./convert-batch.sh
```

Converts all `.docx` files in current directory and `docx manuals/` subdirectory.

**Note:** The batch script calls `convert-single.sh` for each file, ensuring identical output quality and consistency.

---

## MkDocs Integration

### Configuration

Add to your `mkdocs.yml`:

```yaml
# mkdocs.yml
site_name: TRIKDIS Knowledgebase
theme:
  name: material
  
markdown_extensions:
  - admonition      # For !!! note blocks
  - attr_list       # For attributes
  - footnotes       # For footnotes
  - tables          # For tables
  - toc:
      permalink: true

nav:
  - Manuals:
      - GT UM ENG 2024 08 08: "manuals/GT UM_ENG_2024 08 08-/index.md"

extra_css:
  - assets/scale.css  # Better typography
```

### Typography Scaling

The included `docs/assets/scale.css` provides better readability without browser zoom:

```css
html { font-size: 18px; }
.md-typeset { line-height: 1.65; }
@media (min-width: 76.25em) { .md-grid { max-width: 75rem; } }
.md-nav, .md-sidebar { font-size: 0.95rem; }
.md-typeset table:not([class]) td, .md-typeset table:not([class]) th { padding: .6em .8em; }
.md-typeset code, .md-typeset pre { font-size: 0.95em; }
.md-typeset .admonition { font-size: 0.98em; }
.md-typeset img { max-width: 100%; height: auto; }
```

---

## Output Examples

### Before (Word)
```
1.1 Installation Process
Note: Important safety information...
Error! Reference source not found.
```

### After (Markdown)
```markdown
### 1.1 Installation Process

!!! note
    Important safety information...
    
see the referenced section
```

---

## QA Checklist

After conversion, verify:
- ✅ File starts with H1 title extracted from product name (e.g., "# GT+ Cellular Communicator")
- ✅ Product image centered with width="400" appears after H1 title
- ✅ No cover page content (removed but product name preserved)
- ✅ Headings: H2 for main sections, H3 for `1.1`, H4 for `1.1.1`
- ✅ Images: Links like `](image3.png)` pointing to same folder
- ✅ Tables: Render as pipe tables or HTML
- ✅ Admonitions: `!!! note` blocks for callouts
- ✅ No Word artifacts: No `{.underline}`, no error references
- ✅ Typography: Clean apostrophes, no backticks

---

## Publishing to GitHub Pages

After converting a DOCX manual, follow this workflow to publish it to https://docs.trikdis.com:

### 1. Convert the DOCX
```bash
cd /Users/local/projects/knowledgebase-conversion-pipeline
./convert-single.sh "docx manuals/your-manual.docx"
```
This creates: `docs/manuals/your-manual/index.md` (with images)

### 2. Copy to Trikdis Docs Repository
```bash
# Navigate to the trikdis-docs repository
cd /Users/local/projects/trikdis-docs/manuals

# Copy the generated manual folder
cp -r /Users/local/projects/knowledgebase-conversion-pipeline/docs/manuals/your-manual/ docs/manual/

# Or for multiple manuals, copy to specific locations in docs/
```

### 3. Update Navigation (if needed)
Edit `mkdocs.yml` to add the new manual to the navigation:
```yaml
nav:
  - Home: index.md
  - Manual: manual/index.md
  - Other Manual: other-manual/index.md  # Add new entries here
```

### 4. Preview Locally (optional)
```bash
cd /Users/local/projects/trikdis-docs/manuals
pipx run --spec mkdocs-material mkdocs serve --dev-addr 127.0.0.1:8000
```
Visit `http://127.0.0.1:8000` to preview before publishing.

### 5. Commit and Push
```bash
git add docs/manual/ mkdocs.yml  # Add new files and navigation changes
git commit -m "Add updated manual with working images"
git push origin main
```

### 6. Automated Deployment
The GitHub Actions workflow automatically:
- Detects the push to `main` branch
- Runs `mkdocs build --strict`
- Deploys to `gh-pages` branch
- Updates https://docs.trikdis.com

**Timeline**: Usually takes 2-5 minutes for the site to update after pushing.

**✅ Images now work perfectly** thanks to the updated conversion pipeline that outputs proper HTML with CSS instead of problematic Pandoc syntax.

---

## Project Files

```
knowledgebase-conversion-pipeline/
├── README.md                    # This documentation
├── check-requirements.sh        # Verify all tools are installed
├── convert-single.sh           # Convert single DOCX → folder/index.md
├── convert-batch.sh            # Convert all DOCX files
│
├── Lua Filters (24 total):
├── strip-cover.lua                      # Remove cover pages (preserve product name)
├── strip-toc.lua                        # Remove Table of Contents
├── promote-strong-top.lua               # Extract product name and create H1 title
├── flatten-two-cell-tables.lua          # Flatten simple tables
├── flatten-instruction-tables.lua       # Flatten multi-row instruction tables
├── unwrap-table-blockquotes.lua         # Remove blockquote wrappers from table cells
├── fix-rowspan-headers.lua              # Fix malformed rowspan table headers
├── normalize-headings.lua               # Fix heading levels for numbered sections
├── strip-manual-heading-numbers.lua     # Remove manual heading numbers
├── move-first-image-to-description.lua  # Position first image
├── split-inline-images.lua              # Separate inline images
├── convert-image-sizes.lua              # Convert image sizes to HTML/CSS
├── softwrap-tokens.lua                  # Handle text wrapping
├── remove-empty-table-columns.lua       # Remove empty separator columns from tables
├── clean-table-pipes.lua                # Fix table pipe characters
├── mark-two-col.lua                     # Mark two-column tables
├── convert-underline.lua                # Convert underline formatting
├── remove-unwanted-blockquotes.lua      # Remove spurious blockquotes
├── maintain-list-continuity.lua         # Fix numbered list continuity
├── strip-classes.lua                    # Remove Word styling classes
├── fix-typography.lua                   # Fix apostrophes and quotes
├── fix-crossrefs.lua                    # Fix broken cross-references
├── remove-standalone-asterisks.lua      # Remove standalone **** markers
├── clean-html-blocks.lua                # Clean HTML blocks
│
├── docs/
│   ├── assets/
│   │   └── scale.css          # Typography scaling for MkDocs
│   └── manuals/               # Output directory
│       └── [Manual Name]/
│           ├── index.md       # Converted content
│           └── *.png          # All images
│
├── docx manuals/              # Source DOCX files
└── betterdocs-styles.css      # CSS for WordPress/BetterDocs (WP-only)
```

---

## Technical Details

### Image Path Handling
The pipeline automatically:
1. Extracts images with Pandoc to a `media/` subfolder
2. Moves all images to the main folder (alongside index.md)
3. Updates all image links to point directly to filenames

### CommonMark Output
Uses `-t commonmark_x+pipe_tables+attributes` for:
- Pipe tables that render in MkDocs
- Attribute support for IDs
- Clean Markdown syntax

### Post-Processing
After Pandoc conversion, the scripts apply sed fixes for:
- Remaining error references
- Image path corrections
- Escaped quotes (`\"` → `"`)
- Escaped apostrophes (`\'` → `'`)
- Standalone `****` markers (removed outside tables)
- Inline table width styles (removed for responsive behavior)
- Any edge cases not caught by filters

### Responsive Table Design
Tables are optimized for responsive behavior:
- Inline `style="width:X%"` removed from `<table>` tags
- CSS handles all table widths: `width: 100%` with `table-layout: fixed`
- `<colgroup>` percentages preserved for column ratios
- Tables resize consistently across all screen sizes

---

## Troubleshooting

### Images not showing in Typora
- Verify images are in the same folder as index.md
- Check that paths are like `](image.png)` not `](media/image.png)`

### Tables not rendering in MkDocs
- Ensure you're using the latest script with CommonMark output
- Check that pipe tables are properly formatted

### Admonitions not working
- Add `admonition` to `markdown_extensions` in mkdocs.yml
- Verify the table-to-admonition filter is running

---

## Updates

### October 2025 - Table Structure & Typography Fixes
- ✅ **Instruction table flattening**: New `flatten-instruction-tables.lua` converts multi-row instruction tables to sequential format
- ✅ **Rowspan header fix**: New `fix-rowspan-headers.lua` filter fixes malformed table headers at AST level
- ✅ **Escaped quotes fix**: Removes backslash escaping from quotes (`\"NETWORK\"` → `"NETWORK"`)
- ✅ **Escaped angle brackets fix**: Removes backslash escaping from angle brackets in Annex tables (`\<z\>` → `<z>`)
- ✅ **Standalone asterisks removal**: New `remove-standalone-asterisks.lua` removes `****` markers outside tables
- ✅ **Empty column removal**: `remove-empty-table-columns.lua` removes separator columns from tables
- ✅ **Table unwrapping**: `unwrap-table-blockquotes.lua` removes blockquote wrappers from cells
- ✅ **Duplicate product image removal**: Perl script removes duplicate centered product images before major sections
- ✅ **Responsive tables**: Removes inline width styles for consistent responsive behavior
- ✅ **Total filters**: Increased from 19 to 24 specialized Lua filters
- ✅ **CSS enhancement**: Centered H1 titles for better manual presentation

### October 2025 - Automatic Product Title Extraction
- ✅ **Automatic title generation**: Extracts product name from DOCX cover page (e.g., "Cellular communicator GT+")
- ✅ **Smart H1 creation**: Creates H1 title in format "[MODEL] Cellular Communicator" (e.g., "GT+ Cellular Communicator")
- ✅ **Product image formatting**: Centers first image with consistent width (400px) after H1 title
- ✅ **Updated filters**: `strip-cover.lua` preserves product name, `promote-strong-top.lua` extracts and transforms it
- ✅ **Works for all products**: GT, GT+, and future models automatically get correct titles

### September 2024 - Core Pipeline
- ✅ Per-manual folder structure with index.md
- ✅ Images in same folder for Typora compatibility
- ✅ 19 Lua filters for comprehensive cleanup
- ✅ Batch script refactored to use convert-single.sh for consistency
- ✅ **Image size fix**: Convert Pandoc `{width=...}` to HTML with CSS for browser compatibility
- ✅ MkDocs Material admonitions support
- ✅ Typography scaling CSS
- ✅ Automatic media folder flattening
- ✅ Cross-reference fixing
- ✅ CommonMark output with pipe tables
- ✅ GitHub Pages deployment workflow documentation

---

## Appendix: WordPress/BetterDocs Integration (WP-only)

**Note: This section is WordPress/BetterDocs specific and NOT used for MkDocs.**

For WordPress/BetterDocs import:
1. Paste Markdown into a BetterDocs draft (Block Editor converts automatically)
2. Use the included `betterdocs-styles.css` for visual numbering

The CSS adds automatic numbering to headings without hardcoding numbers into text.