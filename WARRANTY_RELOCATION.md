# Warranty Section Relocation

## Overview

The `relocate-warranty.lua` filter automatically preserves warranty and safety requirement sections that appear after the Table of Contents in DOCX manuals and relocates them to the bottom of the converted markdown document.

## Problem Solved

All TRIKDIS product manuals contain warranty/limitation of liability content after the TOC but before the main content chapters. Without this filter, these sections were being stripped by the `lua-filters/strip-cover.lua` filter along with the TOC and cover page.

## Warranty Section Patterns

### Pattern 1: "Safety requirements" (GET, GT, GT+)
**Product Type:** Cellular communicators
**Location:** After TOC, before "Description"
**Content:** Brief section with safety warnings and one-sentence warranty mention

**Example (GET manual):**
```
Safety requirements

The communicator should be installed and maintained by qualified personnel.

Prior to installation, please read this manual carefully in order to avoid mistakes
that can lead to malfunction or even damage to the equipment.

Disconnect the power supply before making any electrical connections.

Changes, modifications or repairs not authorized by the manufacturer shall void
your rights under the warranty.

Please act according to your local rules and do not dispose of your unusable
alarm system or its components with other household waste.
```

### Pattern 2: "Warranty and limitation of liability" (SP3)
**Product Type:** Alarm panels
**Location:** After TOC, before main content
**Content:** Complete warranty terms with detailed conditions

**Example (SP3 manual):**
```
Warranty and limitation of liability

The control panel is given a 24-month warranty effective from the date of sale-purchase...

[Full warranty terms with conditions, exclusions, liability limitations]
```

## Multi-Language Support

The filter automatically detects warranty sections in all supported languages:

| Language | "Safety requirements" | "Warranty and limitation..." |
|----------|----------------------|------------------------------|
| **English** | Safety requirements | Warranty and limitation of liability |
| **Lithuanian** | Saugos reikalavimai | Garantija ir atsakomybės apribojimas |
| **Spanish** | Requisitos de seguridad | Garantía y limitación de responsabilidad |
| **Russian** | Требования безопасности | Гарантия и ограничение ответственности |

## How It Works

### Detection Logic
1. **Warranty section markers** are detected as bold paragraphs containing specific text
2. **Section boundaries** are determined by:
   - Start: Warranty heading pattern match
   - End: "Description" heading OR any H2 heading
3. **Content collection** captures all blocks between start and end markers

### Relocation Process
1. First pass: Identify and collect warranty content, remove from original position
2. Second pass: Append warranty content to end of document
3. Result: Warranty section appears as final H2 chapter at bottom

### Pipeline Integration
The filter runs FIRST in the conversion pipeline (line 42 in `scripts/convert-single.sh`), before `lua-filters/strip-cover.lua`:

```bash
--lua-filter="$FILTER_DIR/relocate-warranty.lua" \  # Line 42 - FIRST
--lua-filter="$FILTER_DIR/strip-cover.lua" \        # Line 43
--lua-filter="$FILTER_DIR/strip-toc.lua" \          # Line 44
# ... rest of filters
```

**Why it runs first:**
- Must extract warranty content BEFORE strip-cover removes it
- Inserts warranty before Annex section or at end if no Annex present
- All subsequent filters process the document with warranty already relocated

**Updated behavior (October 13, 2025):**
- If Annex section exists: warranty appears **before Annex**
- If no Annex: warranty appears **at the end of document**
- Multi-language Annex detection (English, Lithuanian, Spanish, Russian)

## Files Modified

### New Files
- **relocate-warranty.lua** - Main filter that detects, extracts, and relocates warranty sections

### Modified Files
- **scripts/convert-single.sh** - Added relocate-warranty.lua as first filter (line 42)
- **scripts/check-requirements.sh** - Added relocate-warranty.lua to filter check list

## Testing

### Manual Testing
Test with any TRIKDIS manual:
```bash
./scripts/convert-single.sh "path/to/manual.docx"
# Check last section of output - should be warranty/safety requirements
```

### Verification Checklist
- [ ] Warranty section appears at bottom of document
- [ ] All warranty content preserved (no text lost)
- [ ] Proper H2 heading ("Safety requirements" or "Warranty and limitation of liability")
- [ ] Works for all product types (GET, GT, GT+, SP3)
- [ ] Works for all language versions (EN, LT, ES, RU)
- [ ] No duplicate warranty sections
- [ ] No warranty content in middle of document

## Common Issues

### Issue: Warranty section not appearing
**Cause:** Filter not running or warranty text doesn't match patterns
**Solution:**
1. Check filter is in pipeline: `grep relocate-warranty scripts/convert-single.sh`
2. Verify warranty text matches patterns in relocate-warranty.lua
3. Check manual's warranty section is bold paragraph (not heading)

### Issue: Warranty appearing in wrong location
**Cause:** Filter running too late in pipeline
**Solution:** Ensure relocate-warranty.lua runs BEFORE lua-filters/strip-cover.lua

### Issue: Warranty content truncated
**Cause:** "Description" heading detection stopping collection too early
**Solution:** Check stop patterns in relocate-warranty.lua match your manual's heading

## Example Output

**Before (from DOCX):**
```
Table of Contents
1. Description
2. Installation
...

Safety requirements  [bold paragraph - was getting stripped]
[warranty content]

# Description
```

**After (in Markdown):**
```markdown
# GET Cellular Communicator

## Description
...

## Installation
...

[all other sections]

## Safety requirements

The communicator should be installed and maintained by qualified personnel.

Prior to installation, please read this manual carefully...

[complete warranty content preserved before Annex]

## Annex

[Annex content follows warranty section]
```

## Result

✅ Every DOCX conversion now automatically:
- Preserves all warranty and safety requirement sections
- Relocates them to bottom as final chapter
- Maintains proper H2 heading structure
- Works across all product lines and languages
- Requires zero manual intervention
