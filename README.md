# Knowledgebase Conversion Pipeline — DOCX → Markdown (Pandoc)

## Purpose

Convert product manuals from **.docx** to clean **Markdown** with correct heading levels and extracted images, ready for **MkDocs** and **Typora**. Automated pipeline with 35 Lua filters plus 13 Python post-processors (48 total). Source files remain unchanged; all normalization happens during conversion.

---

## Prerequisites

* **Pandoc** installed via Homebrew:
  ```bash
  brew install pandoc
  ```
* All Lua filters included in this project (35 active Lua filters + 13 Python post-processors = 48 total)

---

## What the Pipeline Does

### Conversion Features
* **Automatic title extraction**: Extracts product name from DOCX cover page and creates proper H1 title (e.g., "GT+ Cellular Communicator")
* **Product image formatting**: Centers first product image with consistent width (400px) after H1 title (removes duplicates automatically)
* **App store buttons**: Automatically adds clickable Protegus2 app download buttons (Android/iOS/Web) with intelligent detection
* **Bold list titles**: Automatically bolds short text (≤5 words) that precedes bullet lists for visual hierarchy
* **Warranty section relocation**: Automatically moves warranty/safety sections from cover pages to end of document (supports multiple consecutive warranty sections)
* **Folder structure**: Each manual gets its own folder with `index.md` + images in the same folder
* **Clean output**: Removes Word cover pages and Table of Contents (preserves product name for title generation)
* **Heading normalization**: Promotes `1.1 Title` → H3, `1.1.1 Title` → H4 (keeps numbers in text)
* **Table conversion**: Converts ALL tables to clean, human-readable pipe tables in markdown source
* **Admonitions**: Converts Note/Warning/Tip tables to MkDocs admonitions
* **Callouts**: Normalizes GitHub-style `[!NOTE]` blockquotes into MkDocs/Typora-friendly admonitions
* **Typography fixes**: Cleans up backticks, broken cross-references, escaped quotes, and Word artifacts
* **Table structure fixes**: Corrects malformed rowspan headers and ensures proper thead/tbody separation
* **Image optimization**: Extracts and places images in the same folder as index.md
* **Stable image URLs**: Forces `./image.png` paths so assets render even when served without trailing slashes

### Lua Filters (Applied in Order)
The pipeline applies 36 Lua filters to clean and normalize Word documents:

1. **relocate-warranty.lua**: Relocates warranty/safety sections from beginning to end of document (supports multiple consecutive sections as separate H2 headings)
2. **strip-cover.lua**: Removes cover page content but preserves product name (e.g., "Cellular communicator GT+") for title generation
3. **strip-toc.lua**: Removes Word's Table of Contents sections
4. **promote-strong-top.lua**: Extracts product name from bold text and creates H1 title in format "[MODEL] Product Type" (supports Cellular Communicator, Gate Controller, Control Panel, Alarm Panel)
5. **map-docx-heading-levels.lua**: Maps DOCX Word style classes to correct markdown heading levels (H1→H2, H2→H3, H3→H4)
6. **fix-numbered-heading-levels.lua**: Fixes numbered heading levels (works with map-docx-heading-levels)
7. **remove-table-widths.lua**: Removes table widths and merges multi-line cells for pipe table compatibility
8. **flatten-two-cell-tables.lua**: Flattens simple two-cell tables (single row)
9. **flatten-instruction-tables.lua**: Flattens multi-row instruction tables (text + image per row)
10. **unwrap-table-blockquotes.lua**: Removes blockquote wrappers from table cells
11. **convert-image-tables.lua**: Converts tables containing only images to responsive CSS grid layouts
12. **fix-rowspan-headers.lua**: Fixes malformed rowspan table headers by splitting header from data
13. **normalize-headings.lua**: Promotes multi-level numbers (1.1, 1.1.1) to proper heading levels
14. **strip-manual-heading-numbers.lua**: Removes manual heading numbers for clean output
15. **move-first-image-to-description.lua**: Positions first image properly
16. **split-inline-images.lua**: Separates inline images for proper display
17. **convert-image-sizes.lua**: Converts image sizes to HTML with CSS
18. **softwrap-tokens.lua**: Handles text wrapping
19. **remove-empty-table-columns.lua**: Removes empty separator columns from tables (e.g., single-char "S" columns with no data)
20. **clean-table-pipes.lua**: Fixes table pipe characters
21. **mark-two-col.lua**: Marks two-column tables for processing
22. **convert-underline.lua**: Converts underline formatting
23. **convert-blockquote-headings.lua**: Converts blockquote-wrapped headings (e.g., `> **Title**`) to proper markdown headings
24. **remove-unwanted-blockquotes.lua**: Removes spurious blockquotes and feature descriptions incorrectly wrapped as blockquotes
25. **unwrap-post-image-blockquotes.lua**: Unwraps blockquotes that appear after blocks containing images (paragraphs or tables)
26. **maintain-list-continuity.lua**: Ensures numbered lists continue correctly across interruptions
27. **strip-classes.lua**: Removes Word styling classes like `{.underline}`
28. **fix-typography.lua**: Converts backticks to proper apostrophes and removes empty bold formatting
29. **bold-list-titles.lua**: Automatically bolds short text (≤5 words) preceding bullet lists for visual hierarchy
30. **fix-html-tags.lua**: Converts HTML subscript/superscript tags (e.g., `<sub>space</sub>`) to bracketed code format (e.g., `[space]`)
31. **fix-crossrefs.lua**: Replaces "Error! Reference source not found" with "see the referenced section"
32. **fix-admonition-lists.lua**: Fixes broken list numbering in admonitions (resets start to 1)
33. **remove-standalone-asterisks.lua**: Removes standalone `****` markers while preserving them in tables
34. **clean-html-blocks.lua**: Cleans HTML block structures

---

## Quick Start

1. **Check requirements**: `./check-requirements.sh`
2. **Find latest manual**: `./find-latest-manual.sh "/Volumes/TRIKDIS/PRODUKTAI/GT"`
3. **Convert single file**: `./convert-single.sh "filename.docx"`
4. **Preview locally**: `./preview.sh` (serves on http://127.0.0.1:8001)
5. **Convert all files**: `./convert-batch.sh`

---

## Finding Latest Manuals

Use the `find-latest-manual.sh` script to locate the most recent manual for a product:

```bash
# Find latest GT manual
./find-latest-manual.sh "/Volumes/TRIKDIS/PRODUKTAI/GT"

# Find latest GT+ manual
./find-latest-manual.sh "/Volumes/TRIKDIS/PRODUKTAI/GT+"

# Find latest GET manual
./find-latest-manual.sh "/Volumes/TRIKDIS/PRODUKTAI/GET"
```

The script:
- Searches for `.docx` files in the `_EN` subdirectory
- Excludes temporary files (starting with `~$`)
- Excludes archive folders
- Returns the latest manual by alphabetical sort (which corresponds to date: YYYY MM DD)

**Typical output:**
```
/Volumes/TRIKDIS/PRODUKTAI/GT/_EN/GT UM_ENG_2025 09 11.docx
```

**Use in conversion:**
```bash
./convert-single.sh "$(./find-latest-manual.sh /Volumes/TRIKDIS/PRODUKTAI/GT)"
```

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
- ✅ Tables: All tables in clean, human-readable pipe format (`| Column | Column |`)
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
├── Lua Filters (43 total):
├── strip-cover.lua                      # Remove cover pages (preserve product name)
├── strip-toc.lua                        # Remove Table of Contents
├── promote-strong-top.lua               # Extract product name, create H1 (supports gate controllers)
├── map-docx-heading-levels.lua          # Map DOCX styles to heading levels
├── fix-numbered-heading-levels.lua      # Fix numbered heading levels
├── flatten-two-cell-tables.lua          # Flatten simple tables
├── flatten-instruction-tables.lua       # Flatten multi-row instruction tables
├── unwrap-table-blockquotes.lua         # Remove blockquote wrappers from table cells
├── convert-image-tables.lua             # Convert image-only tables to CSS grids (NEW)
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
├── convert-blockquote-headings.lua      # Convert blockquote headings to proper headers (NEW)
├── remove-unwanted-blockquotes.lua      # Remove spurious blockquotes and feature descriptions
├── maintain-list-continuity.lua         # Fix numbered list continuity
├── strip-classes.lua                    # Remove Word styling classes
├── fix-typography.lua                   # Fix apostrophes, quotes, empty bold formatting
├── fix-html-tags.lua                    # Convert HTML sub/sup to bracketed format (NEW)
├── fix-crossrefs.lua                    # Fix broken cross-references
├── fix-admonition-lists.lua             # Fix broken list numbering in admonitions (NEW)
├── remove-standalone-asterisks.lua      # Remove standalone **** markers
├── clean-html-blocks.lua                # Clean HTML blocks
├── remove-table-widths.lua              # Remove table widths and merge multi-line cells
│
├── Python Post-processors:
├── html-tables-to-pipes.py              # Convert HTML tables to pipe tables
├── fix_table_structure.py               # Fix table structure issues
├── normalize-callouts.py                # Normalize callouts
├── fix-relative-images.py               # Fix image paths
├── fix_admonitions.py                   # Fix admonition formatting
├── fix-list-continuity.py               # Fix list continuity
├── reduce-spacing.py                    # Reduce excessive spacing
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

### Table Conversion to Pipe Format
All tables are converted to clean, human-readable pipe tables:

**Process:**
1. **Lua filter** (`remove-table-widths.lua`):
   - Removes column width specifications
   - Merges multi-paragraph cells with " / " separator
   - Removes `<br>` tags and replaces with " / " for single-line cells

2. **Underline preservation** (`convert-underline.lua`):
   - Converts underlined text to special markers: `⟪U⟫text⟪/U⟫`
   - Markers survive GFM pipe table conversion (GFM strips HTML)
   - Works generically for ANY underlined text in ANY table
   - Post-processed to `<u>text</u>` tags after conversion

3. **Rowspan merging** (`html-tables-to-pipes.py`):
   - Merges rowspan cells with `<br>` tags to avoid repetition
   - Example: PARADOX® appears once with models separated by `<br>`
   - Preserves table structure while reducing redundancy

4. **Python post-processor** (`html-tables-to-pipes.py`):
   - Runs AFTER table structure fixes
   - Converts any remaining HTML tables to compact pipe format
   - **Normalizes whitespace**: Joins multi-paragraph cells into single line
   - Creates clean `| Column | Column |` format without excessive padding

5. **Spacing fix** (`fix-table-spacing.py`):
   - Adds blank line before NEW tables only
   - Does NOT add blank lines between table rows
   - Ensures continuous table rows for proper rendering

**Result:**
- Simple tables: `| Name | Quantity |`
- Complex tables: Multi-line content joined with spaces on one line
- Rowspan tables: Manufacturer once, models with `<br>` separators
- Underlines preserved: `<u>PC585</u>` exactly as in DOCX
- All tables human-readable in markdown source
- Render perfectly in MkDocs with `tables` extension

**Example with all features:**
```markdown
| Manufacturer | Model |
|--------------|-------|
| DSC® | <u>PC585</u>, <u>PC1404</u>, <u>PC1565</u> |
| PARADOX® | <u>SPECTRA SP4000</u>, <u>SP5500</u><br><u>MAGELLAN MG5000</u>, <u>MG5050</u> |
```

**Important:** See `TABLE_FIXES.md` for details on 5 table conversion issues resolved (October 2025).

### Heading Level Mapping

DOCX Word style classes are mapped to correct markdown heading levels because the product title takes H1, requiring all DOCX headings to shift down by one level.

**Process:**
1. **Lua filter** (`map-docx-heading-levels.lua`):
   - Maps Word style "Pagrindinis" (main heading) → H2
   - Maps Word style "2-Po-Pag" (second level) → H3
   - Maps Word style "3-po-Pag" (third level) → H4

2. **Follow-up filter** (`fix-numbered-heading-levels.lua`):
   - Works in conjunction with heading level mapping
   - Ensures numbered sections maintain proper hierarchy

**Why This Is Necessary:**
- Product title (extracted from cover) becomes H1 (e.g., "# GT+ Cellular Communicator")
- Original DOCX "Pagrindinis" headings were effectively H1 in the Word document's TOC
- These need to become H2 in markdown to maintain hierarchy
- Similarly, H2 → H3, H3 → H4

**Result:**
- Heading hierarchy matches DOCX Table of Contents exactly
- Markdown structure reflects original document organization
- All future conversions maintain consistent heading levels
- Works automatically for all TRIKDIS product manuals

**Example Mapping:**
```
DOCX Word Style          DOCX TOC Level    Markdown Level
──────────────────────   ──────────────    ──────────────
(Product title)          (not in TOC)      H1 (# Title)
Pagrindinis             Level 1            H2 (## Section)
2-Po-Pag                Level 2            H3 (### Subsection)
3-po-Pag                Level 3            H4 (#### Sub-subsection)
```

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

### Splitting schematic images with multiple diagrams
- **Problem**: Some images contain multiple complete diagrams side-by-side (e.g., DSC on left, PARADOX on right)
- **Solution**: Use `smart-split-schematics.py` to intelligently detect the boundary between diagrams
- **How it works**: Analyzes pixel brightness to find the whitest column (whitespace) in the middle region of the image
- **Result**: Clean split at the actual boundary, not through the diagrams

**Usage**:
```bash
python3 smart-split-schematics.py path/to/image.png
# Creates: image-left.png and image-right.png
```

**Responsive display** (example for GET manual images 22-25):
```html
<div style="max-width: 1200px; margin: 1rem auto;">
  <div style="display: flex; flex-wrap: wrap; justify-content: center; gap: 0;">
    <img src="./image22-left.png" alt="DSC panel" style="width: 41.2%; min-width: 300px; height: auto; border: 0;" />
    <img src="./image22-right.png" alt="PARADOX panel" style="width: 58.8%; min-width: 300px; height: auto; border: 0;" />
  </div>
</div>
```
- **Desktop**: Side-by-side with proportional widths (no distortion)
- **Mobile**: Stacked vertically, center-aligned (min-width: 300px triggers stacking)

---

## Protegus2 App Store Buttons

### Automatic Detection and Insertion

The pipeline automatically adds clickable Protegus2 app download buttons for manuals that include mobile app integration. This is a **fully automatic** system that requires zero manual intervention.

### How It Works

**Pattern Detection:**
The system searches for the text pattern: "Download and launch the Protegus2 app" in the converted markdown.

**Intelligent Button Handling:**

1. **Try to extract from DOCX** (if buttons are present):
   - Searches for button images between "Download...Protegus" and "Log in/Launch" text markers
   - Uses document structure analysis (Pandoc AST) to find images in the correct location
   - Validates images are actually app store buttons (< 15KB size check)
   - Rejects large manual images that happen to have similar filenames

2. **Fall back to standard buttons** (if DOCX doesn't contain buttons):
   - Automatically copies standard button images from `app-store-buttons/` directory
   - Uses unique filenames (`protegus-*.png`) to avoid overwriting manual images
   - Ensures consistent appearance across all manuals

**Button HTML Generation:**
Creates clickable HTML after the download instruction:

```html
<div style="margin: 20px 0; text-align: left;">
  <a href="https://play.google.com/store/apps/details?id=lt.apps.protegus2" target="_blank">
    <img src="./protegus-android.png" alt="Get it on Google Play" style="height:50px;">
  </a>
  <a href="https://www.protegus.app" target="_blank">
    <img src="./protegus-web.png" alt="Open Web App" style="height:50px;">
  </a>
  <a href="https://apps.apple.com/us/app/protegus-2/id1555450252" target="_blank">
    <img src="./protegus-ios.png" alt="Download on the App Store" style="height:50px;">
  </a>
</div>
```

### Standard Button Library

Located in `app-store-buttons/` directory:
- **protegus-android.png** (3.2 KB) - Google Play Store button
- **protegus-ios.png** (1.5 KB) - Apple App Store button
- **protegus-web.png** (3.4 KB) - Web app button

These buttons are sourced from the GATOR WiFi manual and serve as fallbacks for all manuals.

### Key Features

✅ **Zero manual work** - Writers just convert the DOCX, buttons added automatically
✅ **Intelligent detection** - Only adds buttons if Protegus2 download section exists
✅ **Safe filename handling** - Uses unique `protegus-*.png` names to preserve manual images
✅ **Consistent URLs** - All buttons link to correct app stores
✅ **Works for all formats** - Handles buttons in tables, standalone, or missing entirely

### Files Involved

- **extract-protegus-buttons.py**: Extracts buttons from DOCX by document position
- **add-app-store-buttons.py**: Adds clickable HTML with intelligent fallback logic
- **app-store-buttons/**: Standard button image library

### Example Output

**GATOR Cellular** (no buttons in DOCX):
- Uses standard buttons: `protegus-android.png`, `protegus-ios.png`, `protegus-web.png`
- Original wiring diagrams preserved: `image16-21.png`

**GATOR WiFi** (buttons in DOCX):
- Uses extracted buttons: `image16-18.png` (validated as buttons by size)

**SP3 Control Panel** (no Protegus2 section):
- No buttons added (script detects absence of download instruction)

---

## Updates

### October 27, 2025 - Automatic App Store Buttons System

**Problem**: Manuals with Protegus2 app integration needed consistent, clickable app store buttons.

**Solution**: Created fully automatic system that:
- Detects Protegus2 download sections by document pattern
- Extracts button images from DOCX if present (with validation)
- Falls back to standard button library if needed
- Uses unique filenames to avoid overwriting manual images

**Components**:
1. **extract-protegus-buttons.py** - Position-based button detection using Pandoc AST
2. **add-app-store-buttons.py** - Intelligent button insertion with size validation
3. **app-store-buttons/** - Standard button library (protegus-android/ios/web.png)

**Result**: All manuals with Protegus2 integration automatically get clickable app store buttons with zero manual intervention.



### October 23, 2025 - GSM to Cellular Terminology Replacement

**Automated Terminology Update System**

**Problem:** GATOR and other gate controller manuals used outdated "GSM" terminology that needed to be replaced with modern "Cellular" terminology.

**Solution:** Created `replace-gsm-with-cellular.py` post-processor script that automatically replaces all GSM references with Cellular throughout the document.

**Features:**
- **Handles line breaks**: Uses regex DOTALL flag to match patterns across line breaks
- **Comprehensive coverage**: Replaces GSM in all contexts (gate controller, controller, network, antenna, signal, modem)
- **Case preservation**: Maintains original capitalization patterns
- **Technical specs included**: Even replaces in technical specifications ("2G GSM modem" → "2G cellular modem")

**Title Update:**
Modified `promote-strong-top.lua` to generate "[MODEL] Cellular Gate Controller" instead of "[MODEL] Gate Controller"

**Replacements:**
```
GSM gate controller → Cellular gate controller
GSM controller → Cellular controller
GSM network → Cellular network
GSM antenna → Cellular antenna
GSM signal → Cellular signal
GSM modem → Cellular modem
2G GSM modem → 2G cellular modem
```

**Pipeline Integration:** Runs automatically after structure fixes, before image optimization

**Result:** GATOR manual now uses modern Cellular terminology throughout ✅

### October 23, 2025 - Image Repositioning for Sentence-Splitting Cases

**New Filter Created: reposition-sentence-splitting-images.lua**

**Problem Solved:**
Images appearing in the middle of sentences, breaking readability:
```markdown
...it activates
<img src="./image10.png" />
the controller's 1IN input...
```

**Solution:**
Created intelligent filter that:
- Detects pattern: Paragraph (no period) → Image → Paragraph/BlockQuote (lowercase start)
- Recognizes lowercase continuation text as sentence continuation
- Merges split paragraphs into complete sentence
- Repositions image ABOVE the merged paragraph

**How It Works:**
1. Scans for images between paragraphs
2. Checks if preceding text lacks sentence-ending punctuation (.!?)
3. Checks if following text starts with lowercase (indicates continuation)
4. Handles both regular paragraphs and BlockQuote-wrapped text
5. Merges the split parts and moves image above

**Result:**
```markdown
<img src="./image10.png" />

The automatic gate... it activates the controller's 1IN input...
```

**Filter Count:** 37 active Lua filters + 13 Python post-processors = **50 total filters**

**Tested With:** GATOR manual section 2.5 - image repositioned correctly ✅

### October 23, 2025 - Section 2.5 Formatting & Image Extraction Fixes

**Three Critical Issues Resolved:**

**Issue 1 - Pandoc API Bug in flatten-two-cell-tables.lua**
- **Problem**: Images weren't being extracted from two-cell tables (text + image layout)
- **Root Cause**: Incorrect Pandoc API syntax on line 123: `pandoc.Para(pandoc.Inlines(inl))`
- **Fix**: Changed to correct syntax: `pandoc.Para({inl})`
- **Impact**: Filter was failing silently, preventing image extraction from tables

**Issue 2 - Mass Image Removal (68 out of 72 images missing)**
- **Problem**: After implementing section 2.5 fixes, all images extracted from tables disappeared
- **Root Cause**: `move-first-image-to-description.lua` was removing ALL standalone images before Description heading
- **Investigation**: Systematic debugging revealed filter removed images at indices before Description
- **Fix**: Modified filter to only remove FIRST image (cover image), preserving table-extracted images
- **Result**: 65 images now correctly appear in GATOR manual

**Issue 3 - "/" Separators Instead of Paragraph Breaks**
- **Problem**: Text showed " / " between sentences instead of proper paragraph breaks
- **Example**: "All wiring... / The purposes and voltages..."
- **Root Cause**: Filter order - `remove-table-widths.lua` ran before `flatten-two-cell-tables.lua`
- **Fix**: Swapped filter order in convert-single.sh (line 50 vs 52)
- **Result**: Clean paragraph breaks throughout section 2.5

**Section 2.5 Specific Enhancements:**
- Added sed command to bold first sentence: "All wiring should be done with the power supply disconnected."
- Added perl command to unwrap blockquotes after image10.png
- Result matches PDF source structure exactly

**Files Modified:**
- `filters/flatten-two-cell-tables.lua` - Fixed Pandoc API syntax bug (line 123)
- `move-first-image-to-description.lua` - Only remove first (cover) image, not all images
- `convert-single.sh` - Swapped filter order, added section 2.5 formatting commands

**Verification:**
- ✅ Section 2.5 first sentence bold
- ✅ Clean paragraph breaks (no "/" separators)
- ✅ Image10.png positioned correctly after text
- ✅ No blockquote wrappers on continuation text
- ✅ All 65 images preserved in GATOR manual

**Debugging Methodology:**
Used systematic approach to isolate the image removal issue:
1. Tested filter in isolation → 72 images ✓
2. Added filters incrementally (binary search: 4→7→8→9→10)
3. Pinpointed `move-first-image-to-description.lua` as culprit (72→10 images when added)
4. Modified filter logic to preserve table-extracted images

### October 22, 2025 - Filter Cleanup & Archival

**Pipeline Cleanup:**
Archived 10 unused Lua filters to reduce clutter and clarify which filters are actually used in the conversion pipeline.

**Archived Filters (moved to `archive/unused-filters/`):**
- Old versions replaced by improved filters: 8 filters
  - `append-warranty.lua`, `preserve-warranty.lua` → replaced by `relocate-warranty.lua`
  - `clean-table-blockquotes.lua` → replaced by `unwrap-table-blockquotes.lua`
  - `fix-rowspan-tables.lua`, `flatten-rowspan.lua` → replaced by `fix-rowspan-headers.lua`
  - `flatten-numbered-list-tables.lua` → functionality merged into other filters
  - `flatten-two-cell-tables.lua` → duplicate (version in `filters/` subdirectory is used)
- Experimental filters never used: 2 filters
  - `extract-table-images.lua` (4664 bytes)
  - `force-markdown-tables.lua` (1988 bytes)

**Result:**
- **Before cleanup**: 45 Lua filter files on disk
- **After cleanup**: 36 active Lua filters + 13 Python post-processors = **49 total active filters**
- **Archived**: 9 unused Lua filters preserved in `archive/unused-filters/` with documentation (unwrap-post-image-blockquotes.lua re-activated October 2025)

**Benefits:**
- Clearer project structure (only active filters in main directory)
- Easier to understand the pipeline (no confusion about which filters are used)
- Filters preserved for reference (not deleted, just archived)
- Documentation updated to reflect accurate counts

See `archive/unused-filters/README.md` for details about each archived filter.

### October 22, 2025 - Duplicate Cover Images & Bold List Titles Fixed

**Two Production Issues Resolved:**

**Issue 1 - Duplicate Cover Images (GET Manual)**
- **Problem**: GET manual showed two identical cover images after H1 title
- **Root Cause**: Both `move-first-image-to-description.lua` filter AND sed command were creating centered images
- **Fix Applied**:
  - Disabled conflicting sed command (line 101 in convert-single.sh)
  - Enhanced Lua filter to remove ALL images before Description heading
  - Added `remove-duplicate-cover-images.py` as safety net for edge cases
- **Result**: Only ONE cover image appears after H1 title (all future manuals)

**Issue 2 - List Titles Not Bold (GATOR Manual)**
- **Problem**: Short text like "Remote control", "Messages for users" should be bold when preceding bullet lists
- **Solution**: Created `bold-list-titles.lua` filter
  - Automatically bolds paragraphs with ≤5 words that immediately precede bullet lists
  - Only applies in Features/Description sections to avoid false positives
  - Provides visual hierarchy for list section titles
- **Result**: List titles now properly formatted across all manuals

**Files Changed:**
- NEW: `bold-list-titles.lua` - Automatic bold formatting for list titles
- NEW: `remove-duplicate-cover-images.py` - Safety net for duplicate images
- MODIFIED: `move-first-image-to-description.lua` - Enhanced to remove all cover images
- MODIFIED: `convert-single.sh` - Disabled conflicting sed, added new filters

**Tested With:**
- GET Manual: Duplicate image removed ✅
- GATOR Manual: List titles now bold ✅
- Both fixes apply automatically to all future conversions

**Filter Count:** Added bold-list-titles.lua and remove-duplicate-cover-images.py (35 Lua + 13 Python = 48 total active filters)

### October 22, 2025 - SP3 Manual Final Fixes (Ready for Production)

**SP3 Control Panel Manual** - Completed remaining fixes, now ready for public release:

**3 Critical Fixes:**
1. ✅ **Cover Image Position** - Fixed `move-first-image-to-description.lua` to check for Description as H1 or H2
   - SP3 uses H1 "Description" (not H2 like GT manuals)
   - Cover image now correctly positioned between product title and Description heading

2. ✅ **Heading Hierarchy** - Created `demote-extra-h1.lua` filter for proper H1/H2 structure
   - Ensures only ONE H1 (product title) in entire document
   - Uses pattern matching to identify product titles (Control Panel, Cellular Communicator, etc.)
   - Demotes all non-product H1 headings to H2
   - Removed conflicting sed commands that were re-promoting headings

3. ✅ **Stray Images** - Added sed command to remove image3.png interrupting Features list
   - Runs after all Python post-processors
   - Verified against PDF - image doesn't exist in original

**New Filter Created:**
- `demote-extra-h1.lua` - Pattern-based H1 heading management

**Filters Updated:**
- `move-first-image-to-description.lua` - Now checks H1 or H2 for Description heading
- `strip-cover.lua` - Preserves cover image for positioning
- `strip-toc.lua` - Fixed H1 recognition for SP3-style Table of Contents

**Pipeline Updated:**
- Added `demote-extra-h1.lua` after `promote-strong-top.lua` in filter chain
- Removed redundant sed heading promotion commands (lines 156-160)
- Added image3.png removal after Python post-processors

**Status:** ✅ SP3 manual ready for public release at https://docs.trikdis.com

### October 16, 2025 - SP3 Manual Conversion & Gate Controller Support

**SP3 Control Panel Manual** - First successful conversion of a control panel manual (non-cellular communicator product):

**8 Issues Identified and Fixed:**
1. ✅ **Missing H1 Title** - Added pattern to convert control panel titles to H1
2. ✅ **Empty Bold Formatting** - Extended `fix-typography.lua` to remove `**  **` artifacts
3. ✅ **Blockquotes Misused as Headings** - Created `convert-blockquote-headings.lua` filter
4. ✅ **HTML Subscript Tags** - Created `fix-html-tags.lua` to convert `<sub>space</sub>` to `[space]`
5. ✅ **Admonition List Numbering** - Created `fix-admonition-lists.lua` to reset list starts to 1
6. ✅ **Quoted Admonition Titles** - Enhanced `fix_admonitions.py` to move quoted titles to declaration
7. ✅ **Feature Description Blockquotes** - Extended `remove-unwanted-blockquotes.lua` with 5 new patterns
8. ✅ **Image-Only Tables** - Created `convert-image-tables.lua` for responsive CSS grid layouts

**4 New Filters Created:**
- `convert-blockquote-headings.lua` - Converts blockquote headings to proper markdown headers
- `fix-html-tags.lua` - Converts HTML subscript/superscript to bracketed code format
- `fix-admonition-lists.lua` - Resets list numbering inside admonitions
- `convert-image-tables.lua` - Converts image-only tables to responsive grids

**3 Existing Filters Extended:**
- `fix-typography.lua` - Added empty bold removal
- `promote-strong-top.lua` - Added H2→H1 logic for SP3-style docs
- `remove-unwanted-blockquotes.lua` - Added 5 feature description patterns

**Gate Controller Support Added:**
- ✅ Pattern recognition for "GSM gate controller [MODEL]" products
- ✅ Automatic H1 title generation (e.g., "# GATOR Gate Controller")
- ✅ Cover image positioning for gate controller manuals
- ✅ Tested with GATOR manual - full compatibility confirmed

**Manuals Converted Successfully:**
- SP3 Control Panel (SP3_TAIM_EN_2025 09 12) - 1542 lines, 75 images
- GT Cellular Communicator (GT UM_ENG_2025 09 11) - 59 images, 6 multi-state tables
- GT+ Cellular Communicator (GT+ UM_ENG_2025 09 11) - 60 images, 6 multi-state tables
- GET Cellular Communicator (GET UM_ENG_2025 09 03) - 59 images, split schematics
- Gator Gate Controller (GATOR_UM_ENG_2025 10 16) - 76 images, 3 multi-state tables

**Filter Count Update:**
- Increased from 39 to 43 total filters (4 new + 3 extended = 7 enhancements)

**Generic Compatibility:**
All filters designed to work with:
- Cellular Communicators (GT, GT+, GET)
- Gate Controllers (Gator)
- Control Panels (SP3)
- Future TRIKDIS product manuals

**Documentation:**
- `SP3_IMPLEMENTATION_SUMMARY.md` - Complete implementation details
- `SP3_CONVERSION_ISSUES.md` - Issue analysis and solutions
- `NEXT_SESSION_TASKS.md` - Image split validation system (priority task)

### October 13, 2025 - Intelligent Schematic Image Splitting & Pipeline Fixes

**Schematic Image Splitting**:

**Challenge**: Wiring schematic images (section 3.3) show two complete diagrams side-by-side (DSC left, PARADOX right) that need to be split for responsive display.

**Initial attempt**: Splitting at 50% width cut through the middle of each diagram, making both unusable.

**Solution - Smart Split Algorithm**:
- Created `smart-split-schematics.py` that analyzes pixel brightness
- Finds the whitest column (whitespace) in the middle 40% of the image (30-70% width)
- Splits at the detected boundary between diagrams, not through them

**Results**:
- GET manual images: Split at 38.8%-44% (not 50%!)
- GT manual images: Split at 32.8%-64.3% (highly variable)
- GT+ manual images: Split at 37.2%-64.3%
- All splits preserved complete diagrams with correct aspect ratios

**Implementation**:
- Applied to all three manuals (GET, GT, GT+)
- Responsive flexbox layout with proportional widths
- Desktop: Side-by-side seamlessly (no borders)
- Mobile: Stacked vertically, center-aligned

**Dependencies**: `pip3 install Pillow numpy`

**Pipeline Fixes**:

**Issue 1 - Empty Headers**: Some DOCX files produce empty markdown headers (`####  ` with only whitespace).

**Solution**: Added `remove-empty-headers.py` post-processor
- Detects and removes headers with only whitespace
- Prevents empty section headings in output
- Runs after spacing normalization

**Issue 2 - Single-Character Separator Columns**: Some tables have "S" or similar single-character columns that are visual separators.

**Status**: The `remove-empty-table-columns.lua` filter already handles this (lines 85-111), but may not catch all cases depending on table structure. Manual review recommended for tables with separator columns.

**Issue 3 - Warranty/Safety Section Removal**: Warranty and safety requirement sections were being removed with cover page instead of relocated.

**Solution**: Activated `relocate-warranty.lua` filter
- Runs FIRST in pipeline (before strip-cover.lua)
- Extracts warranty/safety sections from beginning of document
- Relocates to bottom, BEFORE Annex section (if present)
- Falls back to end of document if no Annex
- Multi-language support (EN, LT, ES, RU)
- See `WARRANTY_RELOCATION.md` for full details

**Result**: Every DOCX conversion now automatically preserves and correctly positions warranty/safety sections.

**Lesson learned**: Computer vision approach beats manual splitting - let the algorithm find the boundary!

### October 10, 2025 - Multi-State Table Expansion & Rowspan Fix

#### Issue: Multi-State Tables with Missing Descriptions
**Problem**: Tables with rowspan cells (like LED indication tables) were losing all columns except the first two, resulting in missing descriptions for each state.

**Example**: LED indication table had 3 columns (Indicator, Light Status, Description) but only 2 were being converted, losing all the description text.

**Root Cause**: The `html-tables-to-pipes.py` script's `merge_rowspan_rows()` function was hardcoded to only handle 2-column tables (manufacturer + models pattern), dropping any additional columns.

**Fix**:
- ✅ **Updated html-tables-to-pipes.py**: Rewrote rowspan merging logic to handle ANY number of columns
- ✅ **New expand-multi-state-tables.py**: Post-processor that expands tables with `<br>` tags into separate rows
- ✅ **Result**: Multi-state tables now expand correctly with all columns preserved

**Example Output**:
```markdown
| Indicator | Light status | Description |
|-----------|--------------|-------------|
| NETWORK LTE | Off | No connection to cellular network |
| NETWORK LTE | Yellow blinking | Connecting to cellular network |
| NETWORK LTE | Green solid with yellow blinking | Communicator is connected to cellular network |
```

**Benefits**:
- 100% markdown-native tables (no HTML)
- Each state on its own row for clarity
- Works for any table with rowspan structure
- Preserves all column content regardless of table width

**Files Modified**:
- `html-tables-to-pipes.py` - Fixed rowspan column handling
- `expand-multi-state-tables.py` - New script to expand multi-state rows
- `convert-single.sh` - Integrated expand script into pipeline

### October 9, 2025 - Table Conversion Fixes (5 Issues Resolved)

#### Issue 1: Tables in HTML Format Instead of Pipe Tables
- ✅ **Fixed convert-underline.lua**: Removed round-trip markdown conversion that destroyed table structures
- ✅ **Root cause**: Pandoc() function was re-parsing markdown and corrupting tables
- ✅ **Result**: Tables now convert to proper pipe format from Pandoc's initial HTML output

#### Issue 2: Blank Lines Between Every Table Row
- ✅ **Fixed fix-table-spacing.py**: Only adds blank lines before NEW tables, not between rows
- ✅ **Root cause**: Script was treating every line starting with `|` as a table start
- ✅ **Result**: Continuous table rows without blank lines for proper MkDocs rendering

#### Issue 3: Multi-Paragraph Cell Content Split Across Lines
- ✅ **Fixed html-tables-to-pipes.py**: Normalizes whitespace to join multi-paragraph cells on single line
- ✅ **Root cause**: Multi-paragraph cells from HTML preserved newlines intact
- ✅ **Result**: All table rows on single lines with proper `|` separators

#### Issue 4: Repeated Manufacturer Names in Rowspan Tables
- ✅ **Fixed html-tables-to-pipes.py**: Merge rowspan cells with `<br>` tags instead of duplicating
- ✅ **Root cause**: flatten_rowspan_html() was duplicating manufacturer names across spanned rows
- ✅ **Result**: PARADOX® appears once with models separated by `<br>` tags
- ✅ **Example**:
  ```markdown
  | PARADOX® | SPECTRA SP4000...<br>MAGELLAN MG5000...<br>DIGIPLEX EVO48... |
  ```

#### Issue 5: Underlines Lost in Table Cells
- ✅ **Fixed convert-underline.lua**: Marker-based approach preserves underlines through GFM conversion
- ✅ **Root cause**: Pandoc's GFM writer strips HTML tags from table cells
- ✅ **Solution**: Use Unicode markers (⟪U⟫...⟪/U⟫) that survive conversion, then convert to `<u>` tags
- ✅ **Result**: All underlines preserved exactly as in original DOCX
- ✅ **Generic**: Works for ANY underlined text in ANY table
- ✅ **Example**:
  ```markdown
  | DSC® | <u>PC585</u>, <u>PC1404</u>, <u>PC1565</u>... |
  ```

#### Verification
- ✅ **Tested with**: GET, GT, GT+ manuals - all tables working perfectly
- ✅ **Compatible panels table**: PARADOX® once, models with `<br>`, underlines preserved
- ✅ **Specifications table**: Multi-line cells on single rows, proper rendering
- 📝 **Documentation**: `TABLE_FIXES.md` with detailed analysis and code examples

### October 2025 - Human-Readable Pipe Tables & Heading Level Mapping
- ✅ **ALL tables now pipe format**: Every table converts to clean `| Column | Column |` format
- ✅ **Python post-processor**: New `html-tables-to-pipes.py` converts HTML tables to pipes
- ✅ **Compact format**: No excessive padding - clean and readable in source
- ✅ **Multi-line cell handling**: Merges with " / " separator for single-line pipe compatibility
- ✅ **Perfect rendering**: Tables display properly in MkDocs with `tables` extension
- ✅ **Human-readable source**: Markdown files are now truly readable, not just HTML dumps
- ✅ **Heading level mapping**: New `map-docx-heading-levels.lua` maps Word styles to correct markdown levels
- ✅ **TOC hierarchy match**: Heading structure now matches DOCX Table of Contents exactly
- ✅ **Automatic for all conversions**: Works for all TRIKDIS manuals without manual intervention

### October 2025 - Table Structure & Typography Fixes
- ✅ **Instruction table flattening**: New `flatten-instruction-tables.lua` converts multi-row instruction tables to sequential format
- ✅ **Rowspan header fix**: New `fix-rowspan-headers.lua` filter fixes malformed table headers at AST level
- ✅ **Escaped quotes fix**: Removes backslash escaping from quotes (`\"NETWORK\"` → `"NETWORK"`)
- ✅ **Escaped angle brackets fix**: Removes backslash escaping from angle brackets in Annex tables (`\<z\>` → `<z>`)
- ✅ **Standalone asterisks removal**: New `remove-standalone-asterisks.lua` removes `****` markers outside tables
- ✅ **Empty column removal**: `remove-empty-table-columns.lua` removes separator columns from tables
- ✅ **Table unwrapping**: `unwrap-table-blockquotes.lua` removes blockquote wrappers from cells
- ✅ **Duplicate product image removal**: Perl script removes duplicate centered product images before major sections
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