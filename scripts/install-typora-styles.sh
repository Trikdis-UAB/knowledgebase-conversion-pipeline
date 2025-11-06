#!/bin/bash

echo "Installing Typora styles for TRIKDIS documentation..."

# Find Typora theme folder (common locations on macOS)
THEME_DIR=""
if [ -d "$HOME/Library/Application Support/abnerworks.Typora/themes" ]; then
    THEME_DIR="$HOME/Library/Application Support/abnerworks.Typora/themes"
elif [ -d "$HOME/Library/Application Support/Typora/themes" ]; then
    THEME_DIR="$HOME/Library/Application Support/Typora/themes"
fi

if [ -z "$THEME_DIR" ]; then
    echo "❌ Could not find Typora theme directory automatically."
    echo "Please open Typora → Preferences → Appearance → Open Theme Folder"
    echo "Then manually copy base.user.css to that folder."
    exit 1
fi

echo "Found Typora theme directory: $THEME_DIR"

# Copy base.user.css
if [ -f "base.user.css" ]; then
    cp base.user.css "$THEME_DIR/"
    echo "✅ Installed base.user.css to Typora themes folder"
    echo ""
    echo "Next steps:"
    echo "1. Restart Typora"
    echo "2. Enable GitHub alerts: Preferences → Markdown → 'GitHub Style Alert / Callouts'"
    echo "3. Use any theme you like - the styles will apply to all themes"
else
    echo "❌ base.user.css not found in current directory"
    exit 1
fi