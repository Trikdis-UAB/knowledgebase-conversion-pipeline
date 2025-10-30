#!/bin/bash
# Split an image vertically in half (left and right sides)
# Usage: split-image-vertical.sh input.png

if [ $# -lt 1 ]; then
    echo "Usage: split-image-vertical.sh input.png"
    exit 1
fi

INPUT="$1"
BASENAME="${INPUT%.*}"
EXT="${INPUT##*.}"

# Get image dimensions
WIDTH=$(sips -g pixelWidth "$INPUT" | awk '/pixelWidth:/ {print $2}')
HEIGHT=$(sips -g pixelHeight "$INPUT" | awk '/pixelHeight:/ {print $2}')

# Calculate half width
HALF_WIDTH=$((WIDTH / 2))

# Output filenames
LEFT_OUTPUT="${BASENAME}-left.${EXT}"
RIGHT_OUTPUT="${BASENAME}-right.${EXT}"

# Create left half (crop from x=0, width=half)
sips -c "$HEIGHT" "$HALF_WIDTH" --cropOffset 0 0 "$INPUT" --out "$LEFT_OUTPUT" > /dev/null

# Create right half (crop from x=half, width=half)
cp "$INPUT" "$RIGHT_OUTPUT"
sips -c "$HEIGHT" "$HALF_WIDTH" --cropOffset "$HALF_WIDTH" 0 "$RIGHT_OUTPUT" --out "$RIGHT_OUTPUT" > /dev/null

echo "✅ Split $INPUT"
echo "   Left:  $LEFT_OUTPUT (${HALF_WIDTH}x${HEIGHT})"
echo "   Right: $RIGHT_OUTPUT (${HALF_WIDTH}x${HEIGHT})"
