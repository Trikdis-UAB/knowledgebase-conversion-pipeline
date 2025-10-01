# GitHub Alerts Configuration for MkDocs

## Overview
This document explains how to properly configure GitHub-style alerts (`> [!NOTE]`, `> [!IMPORTANT]`) to work in both Typora and MkDocs Material.

## Problem
GitHub alerts use syntax like `> [!NOTE]` and `> [!IMPORTANT]` which:
- Display properly in Typora
- Show as plain blockquotes in MkDocs without proper configuration
- Were working before but got broken during configuration changes

## Solution
Use the `github-callouts` extension from the `markdown-callouts` package which automatically converts GitHub alerts to MkDocs admonitions.

## Required Configuration

### 1. mkdocs.yml
Add `github-callouts` to the markdown_extensions list:

```yaml
markdown_extensions:
  - attr_list
  - admonition
  - sane_lists
  - pymdownx.details
  - pymdownx.superfences
  - github-callouts  # This enables GitHub alerts
```

**CRITICAL**: The extension name must be `github-callouts`, not `markdown_callouts`.

### 2. requirements.txt
Add the extension dependency:

```
mkdocs>=1.6.0
mkdocs-material>=9.0.0
mkdocs-add-number-plugin>=1.2.0
markdown-callouts>=0.3.0
```

## Supported Alert Types
The extension supports these GitHub alert types:

- `> [!NOTE]` - Blue info box
- `> [!TIP]` - Green tip box
- `> [!IMPORTANT]` - Purple important box
- `> [!WARNING]` - Orange warning box
- `> [!CAUTION]` - Red caution box

## How It Works

1. **In Typora**: GitHub alerts display natively with proper styling
2. **In MkDocs**: The `github-callouts` extension converts them to MkDocs admonitions automatically
3. **Result**: Same markdown works perfectly in both environments

## Technical Details

The `github-callouts` extension converts GitHub alert syntax to MkDocs admonitions:
- Input: `> [!NOTE]\n> This is a note`
- Output: `<div class="admonition note"><p class="admonition-title">Note</p><p>This is a note</p></div>`

## Git History Reference
Working configuration was found in commit `d17d5c5b963cd84b4df3a387f64e3daa28438781` from September 22, 2025.

## Troubleshooting

### If alerts show as plain blockquotes:
1. Check that `github-callouts` is in mkdocs.yml extensions list (NOT `markdown_callouts`)
2. Verify `markdown-callouts>=0.3.0` is in requirements.txt (package name is different from extension name)
3. Restart MkDocs dev server after configuration changes
4. For GitHub Pages, ensure the extension is installed in the build environment

### If you see conflicts:
- Do NOT use `pymdownx.blocks.admonition` - it conflicts with `github-callouts`
- Keep the standard `admonition` extension - it works with `github-callouts`

### Common Mistake:
❌ **Wrong**: Using `markdown_callouts` as extension name
✅ **Correct**: Using `github-callouts` as extension name (from `markdown-callouts` package)

## Testing
To verify it's working:
1. Local: Start MkDocs dev server and check that alerts render as styled boxes
2. Live: Check https://docs.trikdis.com/manual/ after deployment

## IMPORTANT NOTE
Never remove `github-callouts` from the configuration. If you need to modify MkDocs extensions, always preserve this one to maintain GitHub alerts compatibility.

## Resolution History

### September 22, 2025 - Issue Resolution
**Problem**: GitHub alerts were showing as plain blockquotes after table structure fixes
**Root Cause**: Wrong extension name `markdown_callouts` instead of `github-callouts`
**Solution**: Changed extension name in mkdocs.yml from `markdown_callouts` to `github-callouts`
**Result**: ✅ GitHub alerts now display as properly styled callout boxes

**Key Learning**: The package is called `markdown-callouts` but the extension name is `github-callouts`