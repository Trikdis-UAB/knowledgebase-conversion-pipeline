# Filter Analysis - Existing vs. Needed for SP3 Issues

**Date:** 2025-10-16
**Purpose:** Identify which filters exist, which need creation, which can be extended

---

## Issue 1: Missing H1 Title (H2 → H1)

### Existing Filter
**`promote-strong-top.lua`**
- Extracts product name from bold text like "Cellular communicator GT+"
- Creates H1 title: "GT+ Cellular Communicator"
- Works for: GT, GT+, GET manuals

### SP3 Problem
- SP3 manual starts with: `## **Security control panel "FLEXi" SP3**`
- Already an H2, not bold paragraph
- `promote-strong-top.lua` doesn't handle this pattern

### Solution
✅ **EXTEND `promote-strong-top.lua`** to:
1. Check if document starts with H2 (before any other content)
2. Convert first H2 to H1
3. Remove bold formatting from heading content
4. Keep existing bold-to-H1 logic for other manuals

### Implementation
Enhance existing filter, don't create new one.

---

## Issue 2: Empty Bold Formatting (`**  **`)

### Existing Filters
**`fix-typography.lua`**
- Only converts backticks to apostrophes
- Very simple: 5 lines

**`remove-standalone-asterisks.lua`**
- Removes `****` markers outside tables
- Good model for removing formatting artifacts

### Solution
✅ **EXTEND `fix-typography.lua`** to:
1. Remove `**  **` patterns
2. Remove `**\s+**` (bold with only whitespace)
3. Keep it as general typography cleanup filter

### Implementation
Add pattern to existing `fix-typography.lua`

---

## Issue 3: Blockquote as Section Headings

### Existing Filters
**`remove-unwanted-blockquotes.lua`**
- Removes blockquotes with specific text patterns
- Unwraps content, doesn't convert to headings

**`unwrap-post-image-blockquotes.lua`**
- Unwraps blockquotes after images
- Doesn't handle heading conversion

**`unwrap-table-blockquotes.lua`**
- Unwraps blockquotes in table cells
- Specific to tables only

### SP3 Problem
```markdown
> **Schematics for connecting sensors.**
> #### SMS command list
```

Should become:
```markdown
#### Schematics for connecting sensors
#### SMS command list
```

### Solution
✅ **CREATE NEW FILTER: `convert-blockquote-headings.lua`**
- Detect blockquotes containing:
  - Only bold text → H4
  - Heading markers (####) → Remove blockquote wrapper
- Generic: works for any manual

### Implementation
New filter required.

---

## Issue 4: Tables Containing Only Images

### Existing Filters
**None** - No filter handles image-only tables

**Related: `extract-table-images.lua`**
- May extract images from tables but doesn't restructure layout

### Solution
✅ **CREATE NEW FILTER: `convert-image-tables.lua`**
- Detect tables where >80% cells are images
- Convert to responsive HTML grid
- Add figure captions if available
- Handle multi-row image grids

### Implementation
New filter required. Complex filter.

---

## Issue 5: Admonition Lists with Broken Numbering

### Existing Filters
**None** - No filter handles admonition content

**Related: `fix_admonitions.py` (Python)**
- Post-processes admonitions
- Doesn't handle list numbering

### Solution
✅ **CREATE NEW FILTER: `fix-admonition-lists.lua`**
- Detect ordered lists in admonitions starting at wrong number
- Reset numbering to start at 1
- Preserve list content

### Implementation
New filter required.

---

## Issue 6: Quoted Admonition Titles

### Existing Filter
**`fix_admonitions.py`** (Python post-processor)
- Already handles admonition formatting
- Located at line ~95 in convert-single.sh

### Solution
✅ **ENHANCE `fix_admonitions.py`**
- Add pattern: `!!! type\n    "title"` → `!!! type "title"`
- Move quoted first line to admonition type line

### Implementation
Extend existing Python script.

---

## Issue 7: Subscript Placeholders (`<sub>space</sub>`)

### Existing Filters
**None** - No filter handles HTML subscript tags

### Solution
✅ **CREATE NEW FILTER: `fix-html-tags.lua`**
- Convert `<sub>space</sub>` → `[space]` in code formatting
- Could also handle other HTML tag cleanup
- Generic name for future HTML tag fixes

### Implementation
New filter required.

---

## Issue 8: Blockquotes for Feature Descriptions

### Existing Filter
**`remove-unwanted-blockquotes.lua`**
- Removes specific blockquote patterns
- Could be extended

### Solution
**Option A:** ✅ **EXTEND `remove-unwanted-blockquotes.lua`**
- Add pattern detection for feature descriptions
- Unwrap these blockquotes to plain paragraphs

**Option B:** Create new filter `convert-description-blockquotes.lua`
- More specific, cleaner separation of concerns

### Recommendation
**Extend existing** - these are just unwanted blockquotes with different patterns.

### Implementation
Extend existing filter.

---

## Issue 9: Image Styling Verification

### Existing Filter
**`convert-image-sizes.lua`**
- Converts Pandoc image attributes to HTML with CSS
- Should work correctly

### Solution
✅ **VERIFY ONLY** - Test that it works with SP3 manual
- No changes needed unless broken

### Implementation
Testing only, no new code.

---

## Summary: Implementation Plan

### Filters to CREATE (4 new)
1. ✅ `convert-blockquote-headings.lua` - Blockquotes → Headings
2. ✅ `convert-image-tables.lua` - Image tables → Responsive grids (COMPLEX)
3. ✅ `fix-admonition-lists.lua` - Fix list numbering in admonitions
4. ✅ `fix-html-tags.lua` - Clean up HTML tags like `<sub>space</sub>`

### Filters to EXTEND (3 existing)
1. ✅ `promote-strong-top.lua` - Add H2→H1 conversion for SP3
2. ✅ `fix-typography.lua` - Add empty bold removal
3. ✅ `remove-unwanted-blockquotes.lua` - Add feature description patterns

### Scripts to ENHANCE (1 Python)
1. ✅ `fix_admonitions.py` - Add quoted title handling

### Filters to VERIFY (1 existing)
1. ✅ `convert-image-sizes.lua` - Test with SP3

---

## Pipeline Integration Order

New/modified filters should be added in this order in `convert-single.sh`:

```bash
# Early in pipeline (before other processing)
--lua-filter="promote-strong-top.lua"              # MODIFIED - H2→H1 + existing

# Middle of pipeline (structural fixes)
--lua-filter="convert-blockquote-headings.lua"     # NEW
--lua-filter="remove-unwanted-blockquotes.lua"     # MODIFIED - enhanced patterns
--lua-filter="convert-image-tables.lua"            # NEW (after table processing)

# Late in pipeline (cleanup)
--lua-filter="fix-typography.lua"                  # MODIFIED - empty bold removal
--lua-filter="fix-html-tags.lua"                   # NEW
--lua-filter="fix-admonition-lists.lua"            # NEW

# Post-processing (Python)
python3 fix_admonitions.py index.md                # MODIFIED
```

---

## Generic Design Principles

All filters MUST:
1. ✅ Work with GT, GT+, GET, SP3, and future manuals
2. ✅ Not hardcode product-specific text
3. ✅ Use pattern matching that generalizes
4. ✅ Include comments explaining logic
5. ✅ Handle edge cases gracefully

---

## Testing Strategy

For each filter:
1. Create test input with issue pattern
2. Test filter individually with Pandoc MCP
3. Verify output matches expected
4. Test with full SP3 manual
5. Test with GT/GT+/GET manuals
6. Check for regressions

---

## Risk Assessment

**Low Risk (extend existing):**
- `fix-typography.lua` - Simple pattern addition
- `remove-unwanted-blockquotes.lua` - Just more patterns

**Medium Risk (enhance logic):**
- `promote-strong-top.lua` - Adding new H2→H1 logic
- `fix_admonitions.py` - Adding title handling

**High Risk (new complex logic):**
- `convert-image-tables.lua` - Complex table→grid conversion
- `convert-blockquote-headings.lua` - Needs careful level detection

**Recommendation:** Start with low risk, test thoroughly before high risk.
