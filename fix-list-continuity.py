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

    i = 0
    while i < len(lines):
        line = lines[i]

        # Check if line is a numbered list item
        list_match = re.match(r'^(\d+)\.\s+(.*)$', line)

        if list_match:
            list_num = int(list_match.group(1))
            list_text = list_match.group(2)

            # If we were in a list and this starts at 1, check if we should continue
            if in_list and list_num == 1:
                # Look back to see if there was an image recently
                found_image = False
                lookback = min(10, len(result_lines))  # Look back up to 10 lines

                for j in range(1, lookback + 1):
                    if len(result_lines) >= j:
                        prev_line = result_lines[-j]
                        # Check for image syntax or empty lines after images
                        if ('<img ' in prev_line or
                            prev_line.strip().startswith('![') or
                            prev_line.strip() == ''):
                            # Look further back for the last actual list item
                            for k in range(j + 1, min(j + 15, len(result_lines) + 1)):
                                if len(result_lines) >= k:
                                    check_line = result_lines[-k]
                                    prev_list_match = re.match(r'^(\d+)\.\s+', check_line)
                                    if prev_list_match:
                                        found_image = True
                                        break
                            break

                if found_image:
                    # Continue the numbering
                    current_list_num += 1
                    line = f"{current_list_num}. {list_text}"
                else:
                    # This is a new list
                    current_list_num = list_num
            else:
                current_list_num = list_num

            in_list = True

        else:
            # Not a list item - check if we should reset
            if line.strip() == '' or line.startswith('#') or line.startswith('***'):
                # Keep in_list state for empty lines, reset for headers/separators
                if line.startswith('#') or line.startswith('***'):
                    in_list = False
                    current_list_num = 0

        result_lines.append(line)
        i += 1

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

    # Write back to file
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(fixed_content)

    print(f"Fixed list continuity in {file_path}")

if __name__ == "__main__":
    main()