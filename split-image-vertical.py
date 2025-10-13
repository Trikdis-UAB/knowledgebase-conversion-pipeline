#!/usr/bin/env python3
"""
Split an image vertically in half (left and right sides).
Usage: split-image-vertical.py input.png
Output: input-left.png and input-right.png
"""

import sys
from PIL import Image

def split_image_vertical(input_path):
    """Split image vertically in half"""
    # Open the image
    img = Image.open(input_path)
    width, height = img.size

    # Calculate middle point
    mid_x = width // 2

    # Split into left and right
    left_img = img.crop((0, 0, mid_x, height))
    right_img = img.crop((mid_x, 0, width, height))

    # Generate output filenames
    base_name = input_path.rsplit('.', 1)[0]
    ext = input_path.rsplit('.', 1)[1] if '.' in input_path else 'png'

    left_output = f"{base_name}-left.{ext}"
    right_output = f"{base_name}-right.{ext}"

    # Save the split images
    left_img.save(left_output, optimize=True)
    right_img.save(right_output, optimize=True)

    print(f"✅ Split {input_path}")
    print(f"   Left:  {left_output} ({mid_x}x{height})")
    print(f"   Right: {right_output} ({mid_x}x{height})")

    return left_output, right_output

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: split-image-vertical.py input.png")
        sys.exit(1)

    split_image_vertical(sys.argv[1])
