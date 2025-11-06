#!/usr/bin/env python3
"""
Diagnose pixel values in the gap region to understand why detection fails.
"""

import sys
from PIL import Image
import numpy as np

def analyze_gap(image_path):
    img = Image.open(image_path)

    # Convert palette images to RGB for proper analysis
    if img.mode == 'P':
        print(f"Converting palette image to RGB...")
        img = img.convert('RGB')

    img_array = np.array(img)
    height, width = img_array.shape[:2]

    # Analyze middle 40% region
    start = int(width * 0.30)
    end = int(width * 0.70)

    print(f"Image: {width}x{height}")
    print(f"Analyzing columns {start}-{end} (middle 40%)\n")

    # Find columns with statistics
    stats = []
    for col in range(start, end):
        column = img_array[:, col]

        if len(img_array.shape) == 3:
            min_val = np.min(column[:, :3])  # RGB only
            max_val = np.max(column[:, :3])
            avg_val = np.mean(column[:, :3])
        else:
            min_val = np.min(column)
            max_val = np.max(column)
            avg_val = np.mean(column)

        stats.append({
            'col': col,
            'min': min_val,
            'max': max_val,
            'avg': avg_val
        })

    # Find the 10 whitest columns by average
    whitest = sorted(stats, key=lambda x: x['avg'], reverse=True)[:10]

    print("Top 10 whitest columns (by average brightness):")
    print("=" * 70)
    for i, s in enumerate(whitest, 1):
        print(f"{i:2d}. Column {s['col']:4d}: "
              f"min={s['min']:3.0f}, max={s['max']:3.0f}, avg={s['avg']:6.2f}")

    print("\n" + "=" * 70)
    print(f"Best split candidate: column {whitest[0]['col']}")
    print(f"  Minimum pixel value: {whitest[0]['min']:.0f} (darkest pixel in column)")
    print(f"  Average brightness: {whitest[0]['avg']:.2f}")

    if whitest[0]['min'] < 200:
        print(f"\n⚠️  WARNING: Even the whitest column has dark pixels (min={whitest[0]['min']:.0f})")
        print(f"   This means NO truly empty (fully white) column exists!")
        print(f"   There are likely faint lines or artifacts crossing the gap.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: diagnose-gap.py image.png")
        sys.exit(1)

    analyze_gap(sys.argv[1])
