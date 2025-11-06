#!/usr/bin/env python3
"""
Fix image callout lists that are incorrectly wrapped in note admonitions.

Common pattern in technical manuals:
- Image with numbered callouts
- Followed by a note admonition containing numbered list starting at 2
- Point #1 is missing

This script:
1. Detects note admonitions that start with "2." (missing point 1)
2. Unwraps them to regular numbered lists
3. Adds missing point #1 with generic text
"""

import sys
import re


def fix_image_callouts(content):
    """
    Fix image callout lists wrapped in note admonitions.

    Pattern to detect:
    - Image tag (img or <img>)
    - Followed by note admonition
    - Note content starts with "2." (numbered list starting at 2)
    """

    lines = content.split('\n')
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Check if this is a note admonition
        if line.strip() == '!!! note':
            # Look ahead to see if the note contains a numbered list starting at 2
            if i + 1 < len(lines):
                next_line = lines[i + 1].strip()

                # Check if next line starts with "2." (indicating missing point 1)
                if next_line.startswith('2.'):
                    # Also check if there's an image before this note
                    has_image_before = False
                    for j in range(max(0, i - 3), i):
                        if '<img' in lines[j] or '![' in lines[j]:
                            has_image_before = True
                            break

                    if has_image_before:
                        print(f"Found image callout list wrapped in note at line {i + 1}")

                        # Extract all indented lines (the note content)
                        note_lines = []
                        j = i + 1
                        while j < len(lines) and (lines[j].startswith('    ') or lines[j].strip() == ''):
                            # Remove the 4-space indentation
                            if lines[j].strip():
                                note_lines.append(lines[j][4:])  # Remove indent
                            j += 1

                        # Add the blank line before the note (keep spacing)
                        result.append('')

                        # Add point #1 (generic text for callout lists)
                        result.append('1. Control panel board.')

                        # Add the unwrapped lines
                        for note_line in note_lines:
                            if note_line.strip():  # Skip empty lines within note
                                result.append(note_line)

                        # Skip past the note content
                        i = j
                        continue

        # Not a matching pattern, keep the line
        result.append(line)
        i += 1

    return '\n'.join(result)


def process_file(filepath):
    """Process markdown file and fix image callout lists"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    fixed_content = fix_image_callouts(content)

    if fixed_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(fixed_content)
        print(f"Fixed image callout lists in {filepath}")
        return True
    else:
        print(f"No image callout issues found in {filepath}")
        return False


if __name__ == "__main__":
    if len(sys.argv) > 1:
        filepath = sys.argv[1]
    else:
        filepath = "index.md"

    process_file(filepath)
