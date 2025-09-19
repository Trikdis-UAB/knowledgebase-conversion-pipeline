#!/bin/bash
# Check if all required tools are available

echo "🔍 Checking requirements for knowledgebase conversion pipeline..."
echo ""

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
  if [ -f "$f" ]; then
    echo "✅ Lua filter: $f found"
  else
    echo "❌ Lua filter: $f not found"
    missing_filters="$missing_filters $f"
  fi
done

if [ -n "$missing_filters" ]; then
  echo "   Make sure you're in the project directory"
  exit 1
fi

# Check if conversion scripts exist
if [ -f "convert-single.sh" ] && [ -f "convert-batch.sh" ]; then
    echo "✅ Conversion scripts: Available"
else
    echo "❌ Conversion scripts: Missing"
    exit 1
fi

echo ""
echo "🎉 All requirements satisfied! Ready to convert DOCX files."
echo ""
echo "Outputs will be written to: \${OUT_DIR:-docs/manuals} (override by exporting OUT_DIR)"
echo ""
echo "Usage:"
echo "  Single file:  ./convert-single.sh 'filename.docx'"
echo "  Batch:        ./convert-batch.sh"