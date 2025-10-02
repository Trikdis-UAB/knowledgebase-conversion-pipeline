#!/bin/bash
set -euo pipefail

# Publish a converted manual to trikdis-docs
# Usage: ./publish.sh "GT+ UM_ENG_2025 09 11" "en/alarm-communicators/gt-plus"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRIKDIS_DOCS="/Users/local/projects/trikdis-docs/manuals"

if [ $# -ne 2 ]; then
  echo "Usage: ./publish.sh \"MANUAL_NAME\" \"DESTINATION_PATH\""
  echo ""
  echo "Example:"
  echo "  ./publish.sh \"GT+ UM_ENG_2025 09 11\" \"en/alarm-communicators/gt-plus\""
  echo ""
  echo "Available manuals:"
  if [ -d "$SCRIPT_DIR/docs/manuals" ]; then
    ls -1 "$SCRIPT_DIR/docs/manuals"
  fi
  exit 1
fi

MANUAL_NAME="$1"
DEST_PATH="$2"

SOURCE_DIR="$SCRIPT_DIR/docs/manuals/$MANUAL_NAME"
DEST_DIR="$TRIKDIS_DOCS/docs/$DEST_PATH"

# Check if source exists
if [ ! -d "$SOURCE_DIR" ]; then
  echo "❌ Manual not found: $SOURCE_DIR"
  echo ""
  echo "Available manuals:"
  ls -1 "$SCRIPT_DIR/docs/manuals"
  exit 1
fi

# Check if trikdis-docs exists
if [ ! -d "$TRIKDIS_DOCS" ]; then
  echo "❌ trikdis-docs not found at: $TRIKDIS_DOCS"
  exit 1
fi

echo "📦 Publishing manual..."
echo "   From: $MANUAL_NAME"
echo "   To:   $DEST_PATH"
echo ""

# Create destination directory
mkdir -p "$DEST_DIR"

# Copy manual
cp -r "$SOURCE_DIR"/* "$DEST_DIR/"

echo "✅ Manual copied to trikdis-docs"
echo ""
echo "📝 Next steps:"
echo "   1. Update trikdis-docs/mkdocs.yml navigation:"
echo "      - Add: $DEST_PATH/index.md"
echo ""
echo "   2. Preview in trikdis-docs:"
echo "      cd $TRIKDIS_DOCS"
echo "      mkdocs serve"
echo ""
echo "   3. If looks good, remove from pipeline:"
echo "      rm -rf \"$SOURCE_DIR\""
echo ""
echo "   4. Commit to trikdis-docs:"
echo "      cd $TRIKDIS_DOCS"
echo "      git add docs/$DEST_PATH"
echo "      git commit -m \"Add $MANUAL_NAME manual\""
echo "      git push"
