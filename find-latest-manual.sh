#!/bin/bash
# Find the latest manual in a product directory
# Usage: ./find-latest-manual.sh "/Volumes/TRIKDIS/PRODUKTAI/GT"

if [ $# -eq 0 ]; then
  echo "Usage: $0 <product_directory>"
  echo "Example: $0 /Volumes/TRIKDIS/PRODUKTAI/GT"
  exit 1
fi

PRODUCT_DIR="$1"

# Find .docx files in _EN subdirectory, excluding:
# - Temp files starting with ~$
# - Files in Archyvas (archive) folders
# Sort and get the latest (last one)
ls -1 "${PRODUCT_DIR}/_EN/"*.docx 2>/dev/null | grep -v "~\\\$" | sort | tail -1
