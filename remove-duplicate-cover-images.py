#!/usr/bin/env python3
"""
Remove Duplicate Cover Images

Removes consecutive centered image divs that appear after the H1 title.
Keeps only the FIRST centered image and removes any duplicates.

This handles cases where the DOCX has multiple cover images that all get
processed and end up as duplicate centered divs in the output.
"""

import sys
import re

def remove_duplicate_cover_images(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Pattern to detect centered image div blocks
    centered_img_pattern = re.compile(r'^<div style="text-align: center;">\s*$')
    img_tag_pattern = re.compile(r'^\s*<img [^>]*>\s*$')
    div_close_pattern = re.compile(r'^</div>\s*$')

    result = []
    i = 0
    seen_first_centered_image = False
    in_centered_image_div = False
    current_div_lines = []

    while i < len(lines):
        line = lines[i]

        # Check if this is the start of a centered image div
        if centered_img_pattern.match(line):
            # Start collecting this div
            in_centered_image_div = True
            current_div_lines = [line]
            i += 1

            # Collect the img tag and closing div
            while i < len(lines) and len(current_div_lines) < 10:  # Max 10 lines for a div
                current_div_lines.append(lines[i])

                # Check if this completes a valid centered image div
                if div_close_pattern.match(lines[i]):
                    # Check if we have an img tag in the collected lines
                    has_img = any(img_tag_pattern.match(l) for l in current_div_lines)

                    if has_img:
                        if not seen_first_centered_image:
                            # Keep the first centered image
                            result.extend(current_div_lines)
                            seen_first_centered_image = True
                        else:
                            # Skip duplicate centered images (don't add to result)
                            pass
                    else:
                        # Not an image div, keep it
                        result.extend(current_div_lines)

                    in_centered_image_div = False
                    current_div_lines = []
                    i += 1
                    break

                i += 1
        else:
            # Not a centered div start, just keep the line
            result.append(line)
            i += 1

    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(result)

    return True

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: remove-duplicate-cover-images.py <file.md>")
        sys.exit(1)

    file_path = sys.argv[1]

    if remove_duplicate_cover_images(file_path):
        print(f"Removed duplicate cover images from {file_path}")
