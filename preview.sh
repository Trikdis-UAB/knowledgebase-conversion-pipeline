#!/bin/bash
set -euo pipefail

# Preview converted manuals using trikdis-docs MkDocs configuration
# This ensures the preview matches exactly how it will look when published

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRIKDIS_DOCS="/Users/local/projects/trikdis-docs/manuals"

# Check if trikdis-docs exists
if [ ! -d "$TRIKDIS_DOCS" ]; then
  echo "❌ trikdis-docs not found at: $TRIKDIS_DOCS"
  echo "   Please ensure the trikdis-docs repository is cloned"
  exit 1
fi

# Check if mkdocs.yml exists in trikdis-docs
if [ ! -f "$TRIKDIS_DOCS/mkdocs.yml" ]; then
  echo "❌ mkdocs.yml not found in trikdis-docs"
  exit 1
fi

# Copy mkdocs.yml and requirements.txt from trikdis-docs
echo "📋 Using configuration from trikdis-docs..."
cp "$TRIKDIS_DOCS/mkdocs.yml" "$SCRIPT_DIR/mkdocs.yml"
cp "$TRIKDIS_DOCS/requirements.txt" "$SCRIPT_DIR/requirements.txt"

# Copy stylesheets and javascripts if they exist
if [ -d "$TRIKDIS_DOCS/docs/stylesheets" ]; then
  mkdir -p "$SCRIPT_DIR/docs/stylesheets"
  cp -r "$TRIKDIS_DOCS/docs/stylesheets/"* "$SCRIPT_DIR/docs/stylesheets/"
fi

if [ -d "$TRIKDIS_DOCS/docs/javascripts" ]; then
  mkdir -p "$SCRIPT_DIR/docs/javascripts"
  cp -r "$TRIKDIS_DOCS/docs/javascripts/"* "$SCRIPT_DIR/docs/javascripts/"
fi

# Copy images (logo, favicon) if they exist
if [ -d "$TRIKDIS_DOCS/docs/images" ]; then
  mkdir -p "$SCRIPT_DIR/docs/images"
  cp -r "$TRIKDIS_DOCS/docs/images/"* "$SCRIPT_DIR/docs/images/"
fi

# Create a simple index.md for preview
cat > "$SCRIPT_DIR/docs/index.md" <<'EOF'
# Manual Conversion Preview

This is a local preview of converted manuals using the production MkDocs configuration.

## Converted Manuals

Browse the sidebar to see converted manuals.

---

*Configuration synced from `/Users/local/projects/trikdis-docs/manuals/`*
EOF

echo "✅ Configuration synced from trikdis-docs"
echo ""
echo "🚀 Starting MkDocs preview server..."
echo "   Opening http://127.0.0.1:8001 in browser..."
echo ""
echo "   Press Ctrl+C to stop"
echo ""

# Open browser after a short delay to let server start
(sleep 2 && open http://127.0.0.1:8001) &

# Serve on different port than trikdis-docs (8001 instead of 8000)
mkdocs serve --dev-addr 127.0.0.1:8001
