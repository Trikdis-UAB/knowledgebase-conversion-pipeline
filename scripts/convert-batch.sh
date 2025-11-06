#!/bin/bash
set -euo pipefail

# Get absolute paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Ensure convert-single.sh exists
[ -f "$SCRIPT_DIR/convert-single.sh" ] || { echo "Missing convert-single.sh"; exit 1; }

count=0
shopt -s nullglob

for f in *.docx "docx manuals"/*.docx; do
  [ -f "$f" ] || continue

  echo "Converting: $f"
  "$SCRIPT_DIR/convert-single.sh" "$f"

  ((count++))
done

echo ""
echo "✓ Batch completed: $count files converted"
