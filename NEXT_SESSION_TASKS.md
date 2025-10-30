# Tasks for Next Session

## Priority: Image Split Validation System

**Problem**: The smart-split-schematics.py algorithm can sometimes split images at suboptimal locations (e.g., image24 was split at 38.8% instead of optimal 53.3% where the widest whitespace gap is located).

**Task**: Create an automated validation system for split images

### Requirements:

1. **Analyze All Split Images**
   - For each image that gets split (e.g., image22-25 in GET manual), automatically detect:
     - All vertical whitespace gaps in the image
     - Width of each gap
     - Brightness/whiteness of each gap
     - Location of widest/brightest gap

2. **Validate Split Location**
   - Compare actual split point vs optimal split point
   - Flag splits that are >10% away from optimal location
   - Report recommended split location

3. **Script Features**
   - Input: Directory containing split images (e.g., `image22.png`, `image22-left.png`, `image22-right.png`)
   - Output: Validation report showing:
     - Which splits are optimal ✅
     - Which splits need adjustment ❌
     - Recommended split percentages

4. **Integration**
   - Run automatically after `smart-split-schematics.py`
   - Optionally: Enhance `smart-split-schematics.py` to find widest gap instead of just whitest column
   - Add to conversion pipeline as quality check

### Example Output:
```
Validating split images in docs/manuals/get-cellular/GET UM_ENG_2025 09 03/

image22.png:
  ✅ Split at 41.2%, optimal is 41.3% (difference: 0.1%)

image23.png:
  ✅ Split at 40.2%, optimal is 40.4% (difference: 0.2%)

image24.png:
  ❌ Split at 38.8%, optimal is 53.3% (difference: 14.5%)
  Recommendation: Re-split at x=640 (53.3%)
  Reason: 62-pixel wide whitespace gap detected

image25.png:
  ✅ Split at 44.0%, optimal is 44.3% (difference: 0.3%)
```

### Files to Create:
- `validate-image-splits.py` - Validation script
- Enhanced `smart-split-schematics.py` - Use "widest gap" algorithm instead of just "whitest column"

### Related Files:
- Current implementation: `/Users/local/projects/knowledgebase-conversion-pipeline/smart-split-schematics.py`
- Manual that uses splits: GET, GT, GT+ cellular communicator manuals

---

## Other Pending Tasks

1. **Deploy Updated Manuals**
   - GT, GT+, GET, Gator, SP3 manuals are ready
   - Copy to trikdis-docs production
   - Git commit and push
   - Verify on docs.trikdis.com

2. **Update README.md**
   - Document 4 new filters created
   - Document 3 filters extended
   - Update filter count from 39 to 43
   - Add gate controller support to documentation
   - Document image split validation system
   - Note Protegus button injection handled by `insert-protegus-buttons.lua`
   - Document Lithuanian/Spanish coverage in the Protegus button filter

3. **Test Filters with Other Products**
   - Verify generic compatibility with different DOCX formats
   - Test with products beyond GT/GET/Gator/SP3

---

## Reference: Today's Achievements (2025-10-16)

### SP3 Manual Conversion Issues (8 Issues Fixed)
1. ✅ Missing H1 Title - Fixed with sed pattern at line 158
2. ✅ Empty Bold Formatting - Extended fix-typography.lua
3. ✅ Blockquotes as Headings - Created convert-blockquote-headings.lua
4. ✅ HTML Subscript Tags - Created fix-html-tags.lua
5. ✅ Admonition List Numbering - Created fix-admonition-lists.lua
6. ✅ Quoted Admonition Titles - Enhanced fix_admonitions.py
7. ✅ Feature Description Blockquotes - Extended remove-unwanted-blockquotes.lua
8. ✅ Image-Only Tables - Created convert-image-tables.lua

### Gate Controller Support Added
- ✅ Added pattern to promote-strong-top.lua (line 85-90)
- ✅ Added sed pattern to convert-single.sh (line 158)
- ✅ Gator manual now has proper H1 title and cover image

### GET Image Split Issue Fixed
- ✅ Analyzed image24 to find optimal split location
- ✅ Discovered widest whitespace gap at 53.3% (was incorrectly split at 38.8%)
- ✅ Re-split image24 with correct proportions
- ✅ Updated markdown with accurate layout

### Manuals Converted
- ✅ GT Cellular (GT UM_ENG_2025 09 11)
- ✅ GT+ Cellular (GT+ UM_ENG_2025 09 11)
- ✅ GET Cellular (GET UM_ENG_2025 09 03)
- ✅ Gator Gate Controller (GATOR_UM_ENG_2025 10 16)
- ✅ SP3 Control Panel (SP3_TAIM_EN_2025 09 12)

All manuals previewed locally at http://127.0.0.1:8000 and ready for deployment.
