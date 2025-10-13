#!/usr/bin/env python3
"""
Fix disposal icon placement in Safety requirements section.

The disposal icon (typically image2.png) should appear with the disposal paragraph,
not with the warranty paragraph.

Usage: python3 fix-disposal-icon.py <file.md>
"""

import re
import sys

def fix_disposal_icon(content):
    """Move disposal icon from warranty paragraph to disposal paragraph."""

    # Pattern: icon followed by warranty text, then disposal paragraph
    pattern = r'(<img[^>]*>)(Changes, modifications or repairs[^.]+\.)\n\n(Please act according to your local rules[^.]+\.)'

    # Replacement: warranty text without icon, then icon with disposal text
    replacement = r'\2\n\n\1\3'

    # Apply the fix
    fixed_content = re.sub(pattern, replacement, content)

    return fixed_content

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 fix-disposal-icon.py <file.md>")
        sys.exit(1)

    file_path = sys.argv[1]

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        fixed_content = fix_disposal_icon(content)

        # Only write if changes were made
        if fixed_content != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(fixed_content)
            print(f"✓ Fixed disposal icon placement in {file_path}")
        else:
            print(f"✓ No disposal icon fix needed in {file_path}")

    except Exception as e:
        print(f"Error processing {file_path}: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
