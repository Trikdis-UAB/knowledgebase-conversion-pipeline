# SP3 Manual Conversion Issues

**Source:** `/Volumes/TRIKDIS/PRODUKTAI/SP3/_ENG/SP3_TAIM_EN_2025 09 12.docx` (PDF)
**Current Output:** `/Users/local/projects/trikdis-docs/manuals/docs/en/alarm-panels/sp3/SP3_TAIM_EN_2025 09 12/index.md`
**Date:** 2025-10-16

## Critical Issues

### 1. Missing H1 Title
**Location:** Line 1
**Current:**
```markdown
## **Security control panel "FLEXi" SP3**
```

**Expected:**
```markdown
# Security control panel "FLEXi" SP3
```

**Problem:** Document starts with H2 instead of H1, and has unnecessary bold formatting.

**Solution:** Create new Lua filter `ensure-h1-title.lua` to:
- Detect if document starts with H2
- Convert first H2 to H1
- Remove bold formatting from title headings

---

### 2. Empty Bold Formatting Artifacts
**Locations:** Lines 212, 647, 683, 733, 869, 1380
**Current:**
```markdown
**  **
```

**Expected:** Remove entirely

**Problem:** Word conversion creates empty bold markers that serve no purpose.

**Solution:** Add to existing `fix-typography.lua` filter or create `remove-empty-formatting.lua`:
- Pattern match `**  **` or `**\s+**`
- Remove these artifacts

---

### 3. Blockquote Misused as Section Headings
**Locations:** Lines 283, 472
**Current:**
```markdown
> **Schematics for connecting sensors.**

> #### SMS command list
```

**Expected:**
```markdown
#### Schematics for connecting sensors

#### SMS command list
```

**Problem:** Blockquotes used for section headings instead of proper markdown headings.

**Solution:** Create Lua filter `convert-blockquote-headings.lua`:
- Detect blockquotes containing only bold text or heading markers
- Convert to appropriate heading level
- For `> **Text**` → `####` (H4)
- For `> #### Text` → `####` (H4) - remove blockquote wrapper

---

### 4. Tables Containing Only Images
**Locations:** Lines 285-294
**Current:**
```markdown
| <img alt="" src="./image8.png" style="width:1.29in;height:0.98in" /> | <img alt="" src="./image9.png" style="width:1.25in;height:0.98in" /> |  | <img alt="" src="./image10.png" style="width:1.23in;height:1.43in" /> |
|----|----|----|----|
```

**Expected:** Image grid or separate images with captions:
```markdown
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem;">
  <figure>
    <img src="./image8.png" alt="NO sensor connection" style="width: 100%;" />
    <figcaption>NO (Normally Open) connection</figcaption>
  </figure>
  <figure>
    <img src="./image9.png" alt="NC sensor connection" style="width: 100%;" />
    <figcaption>NC (Normally Closed) connection</figcaption>
  </figure>
  ...
</div>
```

**Problem:** Images crammed into table cells with empty columns, doesn't render well on mobile.

**Solution:** Create Lua filter `convert-image-tables.lua`:
- Detect tables where >80% of cells are images
- Convert to responsive grid layout with proper HTML
- Extract alt text from surrounding context or use generic descriptions
- Handle multi-row image tables (lines 288-289, 291-292)

---

### 5. Subscript Tag in Text
**Location:** Line 468
**Current:**
```markdown
Structue of SMS message: Command <sub>space</sub> Password <sub>space</sub> Data
```

**Expected:**
```markdown
Structure of SMS message: `Command [space] Password [space] Data`
```

**Problem:** HTML subscript tags used where code formatting or brackets would be clearer.

**Solution:** Create Lua filter `fix-subscript-placeholders.lua`:
- Detect `<sub>space</sub>` pattern
- Convert to `[space]` in code formatting
- Also fix typo: "Structue" → "Structure"

---

### 6. Admonition Note with Broken Numbering
**Location:** Lines 85-99
**Current:**
```markdown
!!! note
    2.  Backup power supply terminal block.

    3.  Main power supply terminal block.

    4.  External terminal block.
```

**Expected:**
```markdown
!!! note
    1. Backup power supply terminal block
    2. Main power supply terminal block
    3. External terminal block
```

**Problem:** Numbered list starts at 2 instead of 1, likely referencing callout numbers in the image above.

**Solution:** Options:
1. **Fix numbering in filter:** Detect admonition lists starting at wrong number and reset
2. **Convert to bullet list:** If numbers reference image callouts
3. **Add context:** "In the diagram above:"

Recommended: Create `fix-admonition-lists.lua` to detect and fix.

---

### 7. Warning Admonition with Quoted Title
**Location:** Lines 434-436
**Current:**
```markdown
!!! warning
    "Important"
    When adding the „FLEXi" SP3 to Protegus2:
```

**Expected:**
```markdown
!!! warning "Important"
    When adding the „FLEXi" SP3 to Protegus2:
```

**Problem:** Admonition title should be on same line as type, not as quoted content.

**Solution:** Extend existing `fix_admonitions.py` or create Lua filter:
- Detect admonitions with quoted text as first line
- Move quoted text to admonition type line as title
- Pattern: `!!! type\n    "title"` → `!!! type "title"`

---

### 8. Blockquotes for Feature Descriptions
**Locations:** Lines 1231-1358 (multiple instances)
**Current:**
```markdown
> After the alarm is armed, the violation of the "Delay" zone is allowed within the exit time...

> When the alarm is armed, a violation of the "Delay" zone starts the entry time counter...
```

**Expected:**
```markdown
**Delay Zone Behavior:**

- After the alarm is armed, the violation of the "Delay" zone is allowed within the exit time...
- When the alarm is armed, a violation of the "Delay" zone starts the entry time counter...
```

**Problem:** Blockquotes used for feature descriptions instead of proper formatting. These should be either:
- Bullet lists under descriptive headings
- Definition lists
- Plain paragraphs

**Solution:** Create Lua filter `convert-description-blockquotes.lua`:
- Detect consecutive blockquotes describing features
- Group related blockquotes
- Convert to appropriate format (bullets or plain paragraphs)

---

## Minor Issues

### 9. Inconsistent Image Styling
**Problem:** Image width/height in inches instead of relative units
**Example:** `style="width:5.480010936132984in;height:3.826674321959755in"`

**Solution:** Already handled by existing `convert-image-sizes.lua` but verify it's working correctly. Should convert to:
```markdown
<img src="./image4.png" alt="" style="width: 100%; max-width: 600px; height: auto;" />
```

---

### 10. Typography Issues
**Minor typos found:**
- Line 468: "Structue" → "Structure"

**Solution:** Can be fixed in `fix-typography.lua` or during manual review.

---

## Implementation Strategy

### Priority 1 - Critical Structural Issues
1. **ensure-h1-title.lua** - Fix document title
2. **convert-blockquote-headings.lua** - Fix misused blockquotes as headings
3. **convert-image-tables.lua** - Fix image-only tables

### Priority 2 - Content Quality Issues
4. **fix-admonition-lists.lua** - Fix broken numbering in admonitions
5. **fix_admonitions.py** (enhance) - Fix quoted titles
6. **remove-empty-formatting.lua** - Remove `**  **` artifacts

### Priority 3 - Minor Improvements
7. **fix-subscript-placeholders.lua** - Fix `<sub>space</sub>` to `[space]`
8. **convert-description-blockquotes.lua** - Convert feature blockquotes to proper format
9. Verify **convert-image-sizes.lua** is working

---

## Testing Plan

1. **Create test document** with all identified issues
2. **Test each filter individually** using Pandoc MCP tool
3. **Test full pipeline** with SP3 manual
4. **Compare output with PDF** for visual verification
5. **Check responsive behavior** on mobile

---

## Notes for Generic Solution

All filters should be designed to work with OTHER manuals too, not just SP3:

- Don't hardcode SP3-specific text
- Use pattern matching that works across documents
- Test with GT, GT+, GET manuals as well
- Document filter logic in comments

---

## Conversion Command

Current conversion command (from `convert-single.sh`):

```bash
env OUT_DIR="/tmp/sp3-test" \
  ./convert-single.sh "/Volumes/TRIKDIS/PRODUKTAI/SP3/_ENG/SP3_TAIM_EN_2025 09 12.docx"
```

After implementing filters, test with:

```bash
cd /Users/local/projects/knowledgebase-conversion-pipeline
env OUT_DIR="/tmp/sp3-fixed" \
  ./convert-single.sh "/Volumes/TRIKDIS/PRODUKTAI/SP3/_ENG/SP3_TAIM_EN_2025 09 12.docx"
```

Then compare:
```bash
diff -u \
  "/Users/local/projects/trikdis-docs/manuals/docs/en/alarm-panels/sp3/SP3_TAIM_EN_2025 09 12/index.md" \
  "/tmp/sp3-fixed/SP3_TAIM_EN_2025 09 12/index.md"
```
