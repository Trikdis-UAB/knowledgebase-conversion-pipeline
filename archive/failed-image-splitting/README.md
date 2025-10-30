# Failed Image Splitting Scripts

**Date Archived**: October 28, 2025

## Why Archived

These scripts attempted to automatically split landscape schematic images that contain two separate diagrams side-by-side (e.g., DSC on left, PARADOX on right) with vertical whitespace between them.

**Problem**: All automated approaches produced incorrect splits that didn't properly separate the diagrams.

**Decision**: Manual splitting when needed is more reliable than faulty automation.

## Scripts Archived

- `auto-split-landscape-schematics.py` - Attempted landscape detection + splitting
- `auto-split-schematics-v2.py` - Variance-based gap detection (version 2)
- `smart-split-schematics.py` - Brightness-based gap detection (version 1)
- `split-image-vertical.py` - Basic vertical split script
- `split-image-vertical.sh` - Shell wrapper for splitting
- `divide_vert` - ImageMagick-based vertical division script

## Original Use Case

Section 3.2 "Schematics for wiring the communicator to a security control panel" in GET/GT/GT+ manuals contains images like:

```
[DSC Diagram] | whitespace | [PARADOX Diagram]
```

These need to be split for responsive display but automated detection failed to find the correct split point.

## Recommendation

For future needs, split these images manually using:
- ImageMagick: `convert image.png -crop WxH+X+Y output.png`
- GIMP or similar image editor
- Visual inspection to find exact boundary

Preserving these scripts for reference only.
