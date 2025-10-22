#!/usr/bin/env python3
"""
Fix image placement in paragraphs:
1. Replace " / " with proper paragraph breaks
2. Move images that split text to end of paragraph (before last sentence)
"""

import re
import sys

def fix_image_placement(filepath):
    """Fix image placement and paragraph separators"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern: Text ending mid-sentence, then image, then continuation text
    # Match: "...text\n\n<img...>\n\ntext..." where first part ends without period
    pattern = re.compile(
        r'(\*\*[^*]+\*\*.*?[^.!?])\s*\n\n(<img[^>]+>)\s*\n\n([^#\n][^\n]*\.)',
        re.MULTILINE | re.DOTALL
    )

    def move_image_to_end(match):
        """Move image from middle to end of paragraph"""
        text_before = match.group(1)
        image = match.group(2)
        text_after = match.group(3)

        # Combine text, then add image after
        combined_text = text_before + ' ' + text_after
        return f"{combined_text}\n\n{image}"

    content = pattern.sub(move_image_to_end, content)

    # Replace " / " with proper paragraph breaks (only in prose, not in tables)
    # Pattern: sentence ending with period/other punctuation, then " / ", then capital letter
    lines = content.split('\n')
    fixed_lines = []
    in_table = False

    for line in lines:
        # Detect table boundaries
        if line.strip().startswith('|') or '|' in line and '---' in line:
            in_table = True
        elif in_table and not line.strip().startswith('|') and '|' not in line:
            in_table = False

        # Only fix " / " outside of tables
        if not in_table:
            # Replace " / " that separates sentences with paragraph break
            # Pattern handles both regular endings and bold markers: .** / Capital
            line = re.sub(r'([.!?])(\*\*)?\s+/\s+([A-Z])', r'\1\2\n\n\3', line)

        fixed_lines.append(line)

    content = '\n'.join(fixed_lines)

    # Write back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Fixed image placement and paragraph separators in {filepath}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        filepath = sys.argv[1]
    else:
        filepath = "index.md"

    fix_image_placement(filepath)
