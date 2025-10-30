#!/usr/bin/env python3
"""
Find truly empty (fully white) vertical columns in landscape images.

Detects columns where ALL pixels are white (no black lines or text whatsoever).
Then finds the widest continuous strip and splits at its center.

Usage: find-empty-column.py input.png [--threshold THRESHOLD] [--min-gap MIN_GAP]
Output: input-left.png and input-right.png (only if valid gap found)

Options:
  --threshold THRESHOLD    Minimum pixel value to be "white" (default: 250)
  --min-gap MIN_GAP        Minimum width of continuous gap in pixels (default: 5)
  --dry-run               Check without splitting
"""

import sys
import argparse
from PIL import Image
import numpy as np


def is_landscape(img):
    """Check if image is in landscape orientation"""
    width, height = img.size
    return width > height


def find_empty_columns(img_array, threshold=250):
    """
    Find columns where ALL pixels are white (above threshold).

    Args:
        img_array: numpy array of image
        threshold: minimum pixel value (0-255) for a pixel to be "white"

    Returns:
        list of column indices that are fully empty
    """
    height, width = img_array.shape[:2]

    # Search in middle 40% of image (30% to 70% of width)
    start_search = int(width * 0.30)
    end_search = int(width * 0.70)

    empty_columns = []

    for col in range(start_search, end_search):
        # Get all pixels in this column
        column = img_array[:, col]

        # Check if ALL pixels are white (above threshold)
        if len(img_array.shape) == 2:  # Grayscale
            min_value = np.min(column)
        elif len(img_array.shape) == 3:  # RGB or RGBA
            if img_array.shape[2] == 4:  # RGBA
                # Check RGB channels (ignore alpha)
                min_value = np.min(column[:, :3])
            else:  # RGB
                min_value = np.min(column)

        # Column is empty if its darkest pixel is still white
        if min_value >= threshold:
            empty_columns.append(col)

    return empty_columns


def find_widest_gap(empty_columns, min_gap=5):
    """
    Find the widest continuous region of empty columns.

    Args:
        empty_columns: list of column indices
        min_gap: minimum width for a valid gap

    Returns:
        tuple: (start_col, end_col, width) or (None, None, 0) if no gap found
    """
    if not empty_columns:
        return None, None, 0

    # Find continuous regions
    regions = []
    current_start = empty_columns[0]
    current_end = empty_columns[0]

    for i in range(1, len(empty_columns)):
        if empty_columns[i] == empty_columns[i-1] + 1:
            # Continue current region
            current_end = empty_columns[i]
        else:
            # End current region, start new one
            width = current_end - current_start + 1
            if width >= min_gap:
                regions.append((current_start, current_end, width))
            current_start = empty_columns[i]
            current_end = empty_columns[i]

    # Don't forget the last region
    width = current_end - current_start + 1
    if width >= min_gap:
        regions.append((current_start, current_end, width))

    if not regions:
        return None, None, 0

    # Return the widest region
    widest = max(regions, key=lambda r: r[2])
    return widest


def split_image_at(img, split_x):
    """Split image vertically at the specified column"""
    width, height = img.size

    left_img = img.crop((0, 0, split_x, height))
    right_img = img.crop((split_x, 0, width, height))

    return left_img, right_img


def main():
    parser = argparse.ArgumentParser(
        description="Find truly empty columns and split landscape schematics",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s image.png                     # Auto-split if empty gap found
  %(prog)s image.png --threshold 245     # More lenient (allow slight gray)
  %(prog)s image.png --min-gap 10        # Require wider gap (10px minimum)
  %(prog)s image.png --dry-run           # Check without splitting
        """
    )

    parser.add_argument('input', help='Input image file')
    parser.add_argument('--threshold', type=int, default=250,
                        help='Minimum pixel value for "white" (default: 250, max: 255)')
    parser.add_argument('--min-gap', type=int, default=5,
                        help='Minimum width of continuous gap in pixels (default: 5)')
    parser.add_argument('--dry-run', action='store_true',
                        help='Check criteria without actually splitting')

    args = parser.parse_args()

    # Load image
    try:
        img = Image.open(args.input)
    except Exception as e:
        print(f"❌ Error: Failed to open image: {e}")
        sys.exit(1)

    # Convert palette images to RGB for proper pixel analysis
    if img.mode == 'P':
        print(f"📋 Converting palette image to RGB...")
        img = img.convert('RGB')
    elif img.mode not in ('RGB', 'RGBA', 'L'):
        print(f"📋 Converting {img.mode} to RGB...")
        img = img.convert('RGB')

    img_array = np.array(img)
    width, height = img.size

    # Check if landscape
    if not is_landscape(img):
        print(f"⏭️  Skipped: Not landscape format (width={width}, height={height})")
        sys.exit(1)

    # Find empty columns
    print(f"🔍 Searching for fully empty columns (threshold={args.threshold})...")
    empty_columns = find_empty_columns(img_array, args.threshold)

    if not empty_columns:
        print(f"❌ No fully empty columns found (all pixels >= {args.threshold})")
        print(f"   Try lowering threshold with --threshold 245")
        sys.exit(1)

    print(f"   Found {len(empty_columns)} empty columns")

    # Find widest gap
    gap_start, gap_end, gap_width = find_widest_gap(empty_columns, args.min_gap)

    if gap_start is None:
        print(f"❌ No continuous gap found (min_gap={args.min_gap}px)")
        print(f"   Try lowering min-gap with --min-gap 3")
        sys.exit(1)

    # Split at center of gap
    split_point = (gap_start + gap_end) // 2

    print(f"✅ Found empty gap: columns {gap_start}-{gap_end} ({gap_width}px wide)")
    print(f"   Split point: x={split_point} ({split_point/width*100:.1f}% of width)")

    if args.dry_run:
        print(f"   (Dry run - no files created)")
        sys.exit(0)

    # Perform the split
    left_img, right_img = split_image_at(img, split_point)

    # Generate output filenames
    base_name = args.input.rsplit('.', 1)[0]
    ext = args.input.rsplit('.', 1)[1] if '.' in args.input else 'png'

    left_output = f"{base_name}-left.{ext}"
    right_output = f"{base_name}-right.{ext}"

    # Save the split images
    left_img.save(left_output, optimize=True)
    right_img.save(right_output, optimize=True)

    print(f"   Left:  {left_output} ({split_point}x{height})")
    print(f"   Right: {right_output} ({width-split_point}x{height})")
    print(f"✅ Split complete!")


if __name__ == "__main__":
    main()
