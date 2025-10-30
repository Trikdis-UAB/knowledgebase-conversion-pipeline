#!/usr/bin/env python3
"""
Automatic landscape schematic image splitter with middle-space detection.

Only splits images that meet BOTH criteria:
1. Landscape format (width > height)
2. Has significant empty space in the middle (indicating two separate diagrams)

Usage: auto-split-landscape-schematics.py input.png [--threshold THRESHOLD]
Output: input-left.png and input-right.png (only if criteria met)

Options:
  --threshold THRESHOLD  Minimum whiteness score (0-255) to consider as empty space (default: 200)
  --dry-run             Check if image would be split without actually splitting
"""

import sys
import argparse
from PIL import Image
import numpy as np


def is_landscape(img):
    """Check if image is in landscape orientation (width > height)"""
    width, height = img.size
    return width > height


def analyze_middle_space(img_array, threshold=200):
    """
    Analyze if there's significant empty vertical space in the middle region.

    Uses TWO detection methods:
    1. Absolute brightness: Column must be brighter than threshold (for white backgrounds)
    2. Relative contrast: Column must be significantly brighter than image average (for any background)

    Returns:
        tuple: (has_empty_space, split_point, brightness_value, detection_method)
    """
    height, width = img_array.shape[:2]

    # Calculate overall image brightness for relative comparison
    if len(img_array.shape) == 2:  # Grayscale
        overall_brightness = np.mean(img_array)
    elif len(img_array.shape) == 3:  # RGB or RGBA
        if img_array.shape[2] == 4:  # RGBA
            overall_brightness = np.mean(img_array[:, :, :3])
        else:  # RGB
            overall_brightness = np.mean(img_array)

    # Search in the middle 40% of the image (30% to 70% of width for landscape)
    # For landscape images, we're looking for vertical empty space between diagrams
    start_col = int(width * 0.30)
    end_col = int(width * 0.70)

    # Calculate brightness score for each column in the middle region
    brightness_scores = []
    for col in range(start_col, end_col):
        # Get the column pixels
        column = img_array[:, col]

        # Calculate average brightness (higher = brighter/emptier)
        if len(img_array.shape) == 2:  # Grayscale
            avg_brightness = np.mean(column)
        elif len(img_array.shape) == 3:  # RGB or RGBA
            if img_array.shape[2] == 4:  # RGBA
                avg_brightness = np.mean(column[:, :3])
            else:  # RGB
                avg_brightness = np.mean(column)

        brightness_scores.append((col, avg_brightness))

    if not brightness_scores:
        return False, None, 0, None

    # Find the brightest column (maximum brightness)
    split_col, max_brightness = max(brightness_scores, key=lambda x: x[1])

    # Method 1: Absolute brightness check (for white/light backgrounds)
    is_bright_enough = max_brightness >= threshold

    # Method 2: Relative contrast check (for any background color)
    # Column should be at least 10% brighter than image average
    relative_contrast = (max_brightness - overall_brightness) / (overall_brightness + 1)  # +1 to avoid division by zero
    has_significant_contrast = relative_contrast >= 0.10  # 10% brighter than average

    # Accept if EITHER method detects empty space
    has_empty_space = is_bright_enough or has_significant_contrast

    detection_method = None
    if is_bright_enough and has_significant_contrast:
        detection_method = "both"
    elif is_bright_enough:
        detection_method = "absolute"
    elif has_significant_contrast:
        detection_method = "relative"

    return has_empty_space, split_col, max_brightness, detection_method


def split_image_vertical(img, split_x):
    """Split image vertically at the specified column"""
    width, height = img.size

    # Split into left and right
    left_img = img.crop((0, 0, split_x, height))
    right_img = img.crop((split_x, 0, width, height))

    return left_img, right_img


def auto_split_landscape(input_path, threshold=200, dry_run=False):
    """
    Automatically split landscape image with middle empty space.

    Args:
        input_path: Path to input image
        threshold: Minimum whiteness (0-255) to consider as empty space
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

    # Check 2: Does it have empty vertical space in the middle?
    has_empty_space, split_point, brightness, method = analyze_middle_space(img_array, threshold)

    if not has_empty_space:
        return {
            "success": False,
            "reason": f"No significant empty space in middle (max brightness={brightness:.1f}, threshold={threshold})",
            "width": width,
            "height": height,
            "brightness": brightness
        }

    # Both criteria met - this image should be split
    result = {
        "success": True,
        "width": width,
        "height": height,
        "split_point": split_point,
        "brightness": brightness,
        "detection_method": method,
        "reason": f"Landscape image with empty space detected (brightness={brightness:.1f}, method={method})"
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
        description="Automatically split landscape schematics with middle empty space",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s image.png                  # Auto-split if criteria met
  %(prog)s image.png --threshold 180  # Lower threshold for grayish backgrounds
  %(prog)s image.png --dry-run        # Check without splitting
        """
    )

    parser.add_argument('input', help='Input image file')
    parser.add_argument('--threshold', type=int, default=200,
                        help='Minimum whiteness (0-255) for empty space (default: 200)')
    parser.add_argument('--dry-run', action='store_true',
                        help='Check criteria without actually splitting')

    args = parser.parse_args()

    # Process the image
    result = auto_split_landscape(args.input, threshold=args.threshold, dry_run=args.dry_run)

    # Print results
    if result["success"]:
        print(f"✅ {result['reason']}")
        print(f"   Image: {args.input} ({result['width']}x{result['height']})")
        print(f"   Split point: x={result['split_point']} ({result['split_point']/result['width']*100:.1f}% of width)")
        print(f"   Brightness: {result['brightness']:.1f}/255")
        print(f"   Detection: {result['detection_method']}")

        if not args.dry_run:
            print(f"   Left:  {result['left_output']} ({result['left_size'][0]}x{result['left_size'][1]})")
            print(f"   Right: {result['right_output']} ({result['right_size'][0]}x{result['right_size'][1]})")
        else:
            print(f"   (Dry run - no files created)")
    else:
        print(f"⏭️  Skipped: {result['reason']}")
        if "width" in result:
            print(f"   Image: {args.input} ({result['width']}x{result['height']})")
        if "brightness" in result:
            print(f"   Brightness: {result['brightness']:.1f}/255 (threshold: {args.threshold})")

    # Exit with appropriate code
    sys.exit(0 if result["success"] or args.dry_run else 1)


if __name__ == "__main__":
    main()
