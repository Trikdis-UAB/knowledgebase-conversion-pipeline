#!/bin/bash
set -euo pipefail

# Preview converted manuals in trikdis-docs with "Work in Progress" section
# Keeps converted manuals separate from production content

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRIKDIS_DOCS="/Users/local/projects/trikdis-docs/manuals"
WIP_DIR="$TRIKDIS_DOCS/docs/wip"

# Check if trikdis-docs exists
if [ ! -d "$TRIKDIS_DOCS" ]; then
  echo "❌ trikdis-docs not found at: $TRIKDIS_DOCS"
  echo "   Please ensure the trikdis-docs repository is cloned"
  exit 1
fi

echo "📋 Syncing converted manuals to trikdis-docs WIP..."

# Clean and create WIP directory
rm -rf "$WIP_DIR"
mkdir -p "$WIP_DIR"

# Create symlink from conversion pipeline docs to trikdis-docs WIP
# This way we don't copy files - they stay in the pipeline
if [ -d "$SCRIPT_DIR/docs/manuals" ]; then
  for manual_dir in "$SCRIPT_DIR/docs/manuals"/*; do
    if [ -d "$manual_dir" ]; then
      manual_name=$(basename "$manual_dir")
      ln -s "$manual_dir" "$WIP_DIR/$manual_name"
    fi
  done
  manual_count=$(ls -1 "$SCRIPT_DIR/docs/manuals" | wc -l)
  echo "   Linked $manual_count manual(s) to WIP"
else
  echo "   No manuals found to preview"
fi

# Update trikdis-docs navigation
cd "$TRIKDIS_DOCS"

# Backup original mkdocs.yml
cp mkdocs.yml mkdocs.yml.backup

# Create WIP navigation section
WIP_NAV=$(cat <<'EOF'
  - Work in Progress:
EOF
)

if [ -d "$WIP_DIR" ]; then
  for manual_link in "$WIP_DIR"/*; do
    if [ -L "$manual_link" ] || [ -d "$manual_link" ]; then
      manual_name=$(basename "$manual_link")
      if [ -f "$manual_link/index.md" ]; then
        manual_path="wip/$manual_name/index.md"
        WIP_NAV="$WIP_NAV"$'\n'"      - $manual_name: $manual_path"
      fi
    fi
  done
fi

# Insert WIP section after last nav item (before extra_css line)
# Only if WIP section doesn't already exist
if ! grep -q "^  - Work in Progress:" mkdocs.yml; then
  LINE_NUM=$(grep -n "^extra_css:" mkdocs.yml | cut -d: -f1)
  head -n $((LINE_NUM - 1)) mkdocs.yml > mkdocs.yml.tmp
  echo "$WIP_NAV" >> mkdocs.yml.tmp
  tail -n +$LINE_NUM mkdocs.yml >> mkdocs.yml.tmp
  mv mkdocs.yml.tmp mkdocs.yml
else
  echo "   WIP section already exists in navigation"
fi

echo "✅ WIP section added to navigation"
echo ""
echo "🚀 Starting MkDocs preview..."
echo "   Visit: http://127.0.0.1:8000"
echo ""
echo "   📁 Work in Progress - Converted manuals from pipeline"
echo "   📁 English - Production manuals"
echo ""
echo "   Press Ctrl+C to stop and clean up"
echo ""

# Cleanup function
cleanup() {
  echo ""
  echo "🧹 Cleaning up..."
  rm -rf "$WIP_DIR"
  mv mkdocs.yml.backup mkdocs.yml
  echo "✅ Cleanup complete"
}

# Register cleanup on exit
trap cleanup EXIT INT TERM

# Open browser after a short delay
(sleep 2 && open http://127.0.0.1:8000) &

# Serve on port 8000
mkdocs serve --dev-addr 127.0.0.1:8000
