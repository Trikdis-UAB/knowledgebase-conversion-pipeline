#!/usr/bin/env python3
"""
Smart schematic image splitter - finds the boundary between two diagrams.
Usage: smart-split-schematics.py input.png
Output: input-left.png and input-right.png
"""

import sys
from PIL import Image
import numpy as np

def find_split_point(img_array):
    """
    Find the best vertical split point by detecting the whitest column
    in the middle region of the image.
    """
    height, width = img_array.shape[:2]

    # Search in the middle 40% of the image (30% to 70% of width)
    start_col = int(width * 0.30)
    end_col = int(width * 0.70)

    # Calculate whiteness score for each column
    whiteness_scores = []
    for col in range(start_col, end_col):
        # Get the column pixels
        column = img_array[:, col]

        # Calculate average brightness (higher = whiter)
        if len(img_array.shape) == 2:  # Grayscale
            avg_brightness = np.mean(column)
        elif len(img_array.shape) == 3:  # RGB or RGBA
            if img_array.shape[2] == 4:  # RGBA
                avg_brightness = np.mean(column[:, :3])
            else:  # RGB
                avg_brightness = np.mean(column)

        whiteness_scores.append((col, avg_brightness))

    # Find the whitest column (maximum brightness)
    split_col = max(whiteness_scores, key=lambda x: x[1])[0]

    return split_col

def smart_split_image(input_path):
    """Split image at the detected boundary between schematics"""
    # Open the image
    img = Image.open(input_path)
    img_array = np.array(img)
    width, height = img.size

    # Find the optimal split point
    split_x = find_split_point(img_array)

    # Split into left and right
    left_img = img.crop((0, 0, split_x, height))
    right_img = img.crop((split_x, 0, width, height))

    # Generate output filenames
    base_name = input_path.rsplit('.', 1)[0]
    ext = input_path.rsplit('.', 1)[1] if '.' in input_path else 'png'

    left_output = f"{base_name}-left.{ext}"
    right_output = f"{base_name}-right.{ext}"

    # Save the split images
    left_img.save(left_output, optimize=True)
    right_img.save(right_output, optimize=True)

    print(f"✅ Smart split at x={split_x} ({split_x/width*100:.1f}% of width)")
    print(f"   Left:  {left_output} ({split_x}x{height})")
    print(f"   Right: {right_output} ({width-split_x}x{height})")

    return left_output, right_output

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: smart-split-schematics.py input.png")
        sys.exit(1)

    try:
        smart_split_image(sys.argv[1])
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
