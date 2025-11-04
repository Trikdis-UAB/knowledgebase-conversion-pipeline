#!/usr/bin/env python3
"""
Remove Duplicate Cover Images

Removes consecutive centered image divs that appear after the H1 title.
Keeps only the FIRST centered image and removes any duplicates.

This handles cases where the DOCX has multiple cover images that all get
processed and end up as duplicate centered divs in the output.
"""

import os
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
    before_first_heading = True

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
            # Track when we hit the first non-title heading (## ...)
            if line.lstrip().startswith('## '):
                before_first_heading = False

            # Drop stray duplicate image lines before the first heading
            if (seen_first_centered_image and before_first_heading and 'image1.png' in line and '<img' in line):
                i += 1
                continue

            # Not a centered div start, keep the line as-is
            result.append(line)
            i += 1

    # If no centered image div was preserved, attempt to insert one after the
    # first H1 using the earliest image reference available.
    if not seen_first_centered_image:
        image_src = None
        manual_dir = os.path.dirname(file_path)

        # Prefer common cover image filenames if present alongside the markdown.
        preferred_names = [
            "image1.png",
            "image1.jpg",
            "image01.png",
            "image01.jpg"
        ]
        for name in preferred_names:
            candidate_path = os.path.join(manual_dir, name)
            if os.path.exists(candidate_path):
                image_src = f"./{name}"
                break

        # Otherwise look for the first explicit image reference in the document,
        # skipping the known stray image3.png that we strip later in the pipeline.
        if not image_src:
            img_tag = re.compile(r'<img[^>]*src="([^"]+)"')
            for line in result:
                match = img_tag.search(line)
                if match:
                    candidate = match.group(1)
                    if candidate.endswith("image3.png"):
                        continue
                    image_src = candidate
                    break

        if image_src:
            insert_idx = 0
            for idx, line in enumerate(result):
                if line.startswith('# '):
                    insert_idx = idx + 1
                    break
            block = []
            if insert_idx > 0 and result[insert_idx - 1].strip() != '':
                block.append('\n')
            block.extend([
                '<div style="text-align: center;">\n',
                f'  <img src="{image_src}" alt="" width="400">\n',
                '</div>\n',
                '\n'
            ])
            result[insert_idx:insert_idx] = block

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
