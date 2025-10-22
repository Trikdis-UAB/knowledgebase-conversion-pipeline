#!/usr/bin/env python3
"""
Fix heading hierarchy issues from DOCX conversion.

Problem: DOCX uses Word styles like {.2-Po-Pag} inconsistently.
- Some H2 headings have no class (main sections)
- Some H2 headings have {.2-Po-Pag} class (should be subsections)

Solution: Demote H2 headings with Word classes to H3 when they follow a plain H2.

Example:
  ## Installation of the system          <- H2 (no class) = main section
  ## Recommended order {.2-Po-Pag}       <- H2 with class = demote to H3

Becomes:
  ## Installation of the system
  ### Recommended order {.2-Po-Pag}
"""

import re
import sys

def fix_heading_hierarchy(content: str) -> str:
    """Fix heading levels based on Word style classes."""

    lines = content.split('\n')
    result = []
    prev_was_plain_h2 = False

    for line in lines:
        # Check if this is an H2 heading
        h2_match = re.match(r'^## (.+)$', line)

        if h2_match:
            heading_content = h2_match.group(1)

            # Check if it has a Word class attribute
            has_class = bool(re.search(r'\{[^}]*\.[0-9]-[Pp]o-[Pp]ag[^}]*\}', heading_content))

            # If previous line was plain H2 and this H2 has a class, demote to H3
            if prev_was_plain_h2 and has_class:
                line = '###' + line[2:]  # Convert ## to ###
                prev_was_plain_h2 = False
            else:
                # This is a plain H2 (no class)
                prev_was_plain_h2 = not has_class
        else:
            # Not an H2, reset tracking unless it's empty line
            if line.strip():
                prev_was_plain_h2 = False

        result.append(line)

    return '\n'.join(result)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: fix-heading-hierarchy.py <file>")
        sys.exit(1)

    filename = sys.argv[1]

    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()

    fixed_content = fix_heading_hierarchy(content)

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(fixed_content)

    print(f"Fixed heading hierarchy in {filename}")
