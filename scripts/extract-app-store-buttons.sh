#!/bin/bash
# extract-app-store-buttons.sh
# Automatically extracts and adds app store button images from DOCX files
# Detects buttons by file size (4-12KB) and position in document

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <docx-file> <output-dir>"
    exit 1
fi

DOCX_FILE="$1"
OUTPUT_DIR="$2"
TEMP_DIR=$(mktemp -d)

# Extract DOCX to temp directory
unzip -q "$DOCX_FILE" -d "$TEMP_DIR"

# Find small images (4-12KB) that are likely app store buttons
# These are typically image16-21 in the media folder
if [ -d "$TEMP_DIR/word/media" ]; then
    # Look for PNG files between 4KB and 12KB
    find "$TEMP_DIR/word/media" -name "*.png" -type f -size +4k -size -12k | while read img; do
        filename=$(basename "$img")
        # Check if filename matches typical button pattern (image16-21)
        if [[ "$filename" =~ ^image(1[6-9]|2[0-1])\.png$ ]]; then
            echo "  Found app store button: $filename"
            cp "$img" "$OUTPUT_DIR/"
        fi
    done
fi

# Cleanup
rm -rf "$TEMP_DIR"
