#!/usr/bin/env python3
"""
Automatic schematic image splitter - finds continuous empty vertical strip between diagrams.

Only splits landscape images (width > height) that have a clear vertical gap between
two separate diagrams (like DSC | gap | PARADOX).

Improvement over v1: Instead of finding single whitest column, finds the longest
continuous region of empty columns, then splits at the center of that region.

Usage: auto-split-schematics-v2.py input.png [--threshold THRESHOLD] [--min-gap MIN_GAP]
Output: input-left.png and input-right.png (only if criteria met)

Options:
  --threshold THRESHOLD    Minimum brightness (0-255) for column to be "empty" (default: 200)
  --min-gap MIN_GAP        Minimum width of continuous gap in pixels (default: 10)
  --dry-run               Check if image would be split without actually splitting
"""

import sys
import argparse
from PIL import Image
import numpy as np


def is_landscape(img):
    """Check if image is in landscape orientation (width > height)"""
    width, height = img.size
    return width > height


def find_continuous_empty_region(img_array, threshold=200, min_gap=10):
    """
    Find the longest continuous region of empty vertical space.

    Uses variance/uniformity instead of absolute brightness to detect gaps.
    A gap has LOW VARIANCE (uniform color) while diagram areas have HIGH VARIANCE
    (lines, text, shapes).

    Returns:
        tuple: (found, start_col, end_col, width, avg_variance)
    """
    height, width = img_array.shape[:2]

    # Search in the middle 40% of the image (30% to 70% of width)
    start_search = int(width * 0.30)
    end_search = int(width * 0.70)

    # Calculate variance for each column (lower = more uniform = likely gap)
    column_variance = []
    for col in range(start_search, end_search):
        column = img_array[:, col]

        # Calculate variance (how much pixels differ from each other)
        if len(img_array.shape) == 2:  # Grayscale
            variance = np.var(column)
        elif len(img_array.shape) == 3:  # RGB or RGBA
            if img_array.shape[2] == 4:  # RGBA
                variance = np.mean([np.var(column[:, i]) for i in range(3)])
            else:  # RGB
                variance = np.mean([np.var(column[:, i]) for i in range(3)])

        column_variance.append((col, variance))

    # Find continuous regions where ALL columns have LOW variance (uniform)
    # Use the threshold parameter as max variance (default 200 is too high, will adjust)
    variance_threshold = threshold  # Will use lower values like 10-50
    regions = []
    current_region_start = None
    current_region_cols = []

    for col, variance in column_variance:
        if variance <= variance_threshold:
            # This column is uniform (low variance = likely empty gap)
            if current_region_start is None:
                # Start new region
                current_region_start = col
                current_region_cols = [(col, variance)]
            else:
                # Continue current region
                current_region_cols.append((col, variance))
        else:
            # This column has content (high variance) - end current region if any
            if current_region_start is not None:
                region_width = len(current_region_cols)
                if region_width >= min_gap:
                    # This region is wide enough to be a gap
                    region_avg = np.mean([v for _, v in current_region_cols])
                    regions.append({
                        'start': current_region_start,
                        'end': current_region_cols[-1][0],
                        'width': region_width,
                        'avg_variance': region_avg
                    })
                # Reset for next region
                current_region_start = None
                current_region_cols = []

    # Don't forget the last region if we ended while in one
    if current_region_start is not None:
        region_width = len(current_region_cols)
        if region_width >= min_gap:
            region_avg = np.mean([v for _, v in current_region_cols])
            regions.append({
                'start': current_region_start,
                'end': current_region_cols[-1][0],
                'width': region_width,
                'avg_variance': region_avg
            })

    if not regions:
        return False, None, None, 0, 0

    # Find the widest region (most likely to be the gap between diagrams)
    widest_region = max(regions, key=lambda r: r['width'])

    return (True,
            widest_region['start'],
            widest_region['end'],
            widest_region['width'],
            widest_region['avg_variance'])


def split_image_vertical(img, split_x):
    """Split image vertically at the specified column"""
    width, height = img.size

    # Split into left and right
    left_img = img.crop((0, 0, split_x, height))
    right_img = img.crop((split_x, 0, width, height))

    return left_img, right_img


def auto_split_schematics(input_path, threshold=200, min_gap=10, dry_run=False):
    """
    Automatically split schematic image with continuous empty vertical strip.

    Args:
        input_path: Path to input image
        threshold: Minimum brightness (0-255) for column to be "empty"
        min_gap: Minimum width of continuous gap in pixels
        dry_run: If True, only check without splitting

    Returns:
        dict: Status information about the operation
    """
    # Open the image
    try:
        img = Image.open(input_path)
    except Exception as e:
        return {"success": False, "reason": f"Failed to open image: {e}"}

    img_array = np.array(img)
    width, height = img.size

    # Check 1: Is it landscape?
    if not is_landscape(img):
        return {
            "success": False,
            "reason": f"Not landscape format (width={width}, height={height})",
            "width": width,
            "height": height
        }

    # Check 2: Does it have continuous empty vertical strip?
    found, gap_start, gap_end, gap_width, avg_variance = find_continuous_empty_region(
        img_array, threshold, min_gap
    )

    if not found:
        return {
            "success": False,
            "reason": f"No continuous empty strip found (max_variance={threshold}, min_gap={min_gap}px)",
            "width": width,
            "height": height
        }

    # Split at the CENTER of the empty region
    split_point = (gap_start + gap_end) // 2

    # Both criteria met - this image should be split
    result = {
        "success": True,
        "width": width,
        "height": height,
        "gap_start": gap_start,
        "gap_end": gap_end,
        "gap_width": gap_width,
        "split_point": split_point,
        "avg_variance": avg_variance,
        "reason": f"Found {gap_width}px wide empty strip (variance={avg_variance:.1f})"
    }

    if dry_run:
        result["dry_run"] = True
        return result

    # Perform the split
    left_img, right_img = split_image_vertical(img, split_point)

    # Generate output filenames
    base_name = input_path.rsplit('.', 1)[0]
    ext = input_path.rsplit('.', 1)[1] if '.' in input_path else 'png'

    left_output = f"{base_name}-left.{ext}"
    right_output = f"{base_name}-right.{ext}"

    # Save the split images
    left_img.save(left_output, optimize=True)
    right_img.save(right_output, optimize=True)

    result["left_output"] = left_output
    result["right_output"] = right_output
    result["left_size"] = (split_point, height)
    result["right_size"] = (width - split_point, height)

    return result


def main():
    parser = argparse.ArgumentParser(
        description="Automatically split schematic images with continuous empty vertical strip",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s image.png                     # Auto-split if gap found
  %(prog)s image.png --threshold 180     # Lower threshold for grayish backgrounds
  %(prog)s image.png --min-gap 20        # Require wider gap (20px minimum)
  %(prog)s image.png --dry-run           # Check without splitting
        """
    )

    parser.add_argument('input', help='Input image file')
    parser.add_argument('--threshold', type=int, default=50,
                        help='Maximum variance for empty column (default: 50, lower=stricter)')
    parser.add_argument('--min-gap', type=int, default=10,
                        help='Minimum width of continuous gap in pixels (default: 10)')
    parser.add_argument('--dry-run', action='store_true',
                        help='Check criteria without actually splitting')

    args = parser.parse_args()

    # Process the image
    result = auto_split_schematics(
        args.input,
        threshold=args.threshold,
        min_gap=args.min_gap,
        dry_run=args.dry_run
    )

    # Print results
    if result["success"]:
        print(f"✅ {result['reason']}")
        print(f"   Image: {args.input} ({result['width']}x{result['height']})")
        print(f"   Gap region: x={result['gap_start']}-{result['gap_end']} ({result['gap_width']}px wide)")
        print(f"   Split point: x={result['split_point']} ({result['split_point']/result['width']*100:.1f}% of width)")
        print(f"   Avg variance: {result['avg_variance']:.1f}")

        if not args.dry_run:
            print(f"   Left:  {result['left_output']} ({result['left_size'][0]}x{result['left_size'][1]})")
            print(f"   Right: {result['right_output']} ({result['right_size'][0]}x{result['right_size'][1]})")
        else:
            print(f"   (Dry run - no files created)")
    else:
        print(f"⏭️  Skipped: {result['reason']}")
        if "width" in result:
            print(f"   Image: {args.input} ({result['width']}x{result['height']})")

    # Exit with appropriate code
    sys.exit(0 if result["success"] or args.dry_run else 1)


if __name__ == "__main__":
    main()
