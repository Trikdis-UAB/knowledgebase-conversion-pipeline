#!/bin/bash
# Check if all required tools are available

echo "🔍 Checking requirements for knowledgebase conversion pipeline..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
FILTER_DIR="${ROOT_DIR}/lua-filters"
cd "$ROOT_DIR" >/dev/null

# Check if pandoc is installed
if command -v pandoc >/dev/null 2>&1; then
    version=$(pandoc --version | head -n1)
    echo "✅ Pandoc: $version"
else
    echo "❌ Pandoc: Not found"
    echo "   Install with: brew install pandoc"
    exit 1
fi

# Check if Lua filters exist
missing_filters=""
for f in normalize-headings.lua strip-toc.lua strip-cover.lua; do
  if [ -f "$FILTER_DIR/$f" ]; then
    echo "✅ Lua filter: $f found"
  else
    echo "❌ Lua filter: $f not found (expected at lua-filters/$f)"
    missing_filters="$missing_filters $f"
  fi
done

if [ -n "$missing_filters" ]; then
  echo "   Lua filters missing. Run this from the repo after pulling latest layout."
  exit 1
fi

# Check if conversion scripts exist
if [ -f "$SCRIPT_DIR/convert-single.sh" ] && [ -f "$SCRIPT_DIR/convert-batch.sh" ]; then
    echo "✅ Conversion scripts: Available"
else
    echo "❌ Conversion scripts: Missing (expected in scripts/)"
    exit 1
fi

echo ""
echo "🎉 All requirements satisfied! Ready to convert DOCX files."
echo ""
echo "Outputs will be written to: \${OUT_DIR:-docs/manuals} (override by exporting OUT_DIR)"
echo ""
echo "Usage:"
echo "  Single file:  ./scripts/convert-single.sh \"filename.docx\""
echo "  Batch:        ./scripts/convert-batch.sh"
