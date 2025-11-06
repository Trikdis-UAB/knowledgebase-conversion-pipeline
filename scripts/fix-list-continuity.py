#!/usr/bin/env python3
"""
Fix numbered list continuity in Markdown files.
This script finds numbered lists that restart at 1 after images and adjusts them
to continue the previous numbering sequence.
"""

import re
import sys
from pathlib import Path

def fix_list_continuity(content):
    """Fix numbered list continuity by adjusting start numbers after images."""
    lines = content.split('\n')
    result_lines = []
    current_list_num = 0
    in_list = False

    for i, line in enumerate(lines):
        # Check if line is a numbered list item
        list_match = re.match(r'^(\d+)\.\s+(.*)$', line)

        if list_match:
            list_num = int(list_match.group(1))
            list_text = list_match.group(2)

            # If this starts at 1 and we were already in a list, check if we should continue
            if list_num == 1 and in_list:
                # Look back for images or admonitions in the last few lines
                found_continuation_context = False
                for j in range(max(0, i-10), i):
                    if j < len(lines):
                        prev_line = lines[j]
                        # Check for images
                        if ('<img ' in prev_line or
                            prev_line.strip().startswith('![') or
                            prev_line.strip().startswith('<img')):
                            found_continuation_context = True
                            break
                        # Check for admonitions (both !!! and > [! formats)
                        if (prev_line.strip().startswith('!!!') or
                            prev_line.strip().startswith('> [!')):
                            found_continuation_context = True
                            break
                        # Check for indented list items (inside admonitions)
                        if re.match(r'^\s{4,}\d+\.\s+', prev_line):
                            found_continuation_context = True
                            break

                # Check for headings that should reset numbering
                found_heading = False
                for j in range(max(0, i-10), i):
                    if j < len(lines):
                        prev_line = lines[j]
                        # ANY heading (##, ###, ####, etc.) resets numbering
                        if prev_line.strip().startswith('#'):
                            found_heading = True
                            break

                # User's algorithm: continue numbering unless there was a heading
                if found_continuation_context and not found_heading:
                    # Continue the numbering
                    current_list_num += 1
                    line = f"{current_list_num}. {list_text}"
                else:
                    # Reset numbering for new sections
                    current_list_num = list_num
            else:
                current_list_num = list_num

            in_list = True

        else:
            # Check for headings that should reset list tracking
            # User's algorithm: ANY heading resets list numbering
            if line.strip().startswith('#'):
                in_list = False
                current_list_num = 0

        result_lines.append(line)

    return '\n'.join(result_lines)

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 fix-list-continuity.py <markdown-file>")
        sys.exit(1)

    file_path = Path(sys.argv[1])

    if not file_path.exists():
        print(f"Error: File {file_path} does not exist")
        sys.exit(1)

    # Read the file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix the list continuity
    fixed_content = fix_list_continuity(content)

    # Only write if there are actual changes
    if fixed_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(fixed_content)
        print(f"Fixed list continuity in {file_path}")
    else:
        print(f"No changes needed in {file_path}")

if __name__ == "__main__":
    main()