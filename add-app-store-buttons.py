#!/usr/bin/env python3
"""
add-app-store-buttons.py
Adds clickable app store buttons after "Download and launch the Protegus2 app" text
Automatically detects which button images are available (image16-21)
"""

import sys
import re
import os

def find_app_store_buttons(directory):
    """Find app store button images in the directory.

    Returns dict with button types and their image filenames.
    """
    buttons = {}

    # Check for various button image patterns
    # Pattern: image16/19 = Google Play, image17/20 = Web, image18/21 = App Store
    android_patterns = ['image16.png', 'image19.png']
    web_patterns = ['image17.png', 'image20.png']
    ios_patterns = ['image18.png', 'image21.png']

    for pattern in android_patterns:
        if os.path.exists(os.path.join(directory, pattern)):
            buttons['android'] = pattern
            break

    for pattern in web_patterns:
        if os.path.exists(os.path.join(directory, pattern)):
            buttons['web'] = pattern
            break

    for pattern in ios_patterns:
        if os.path.exists(os.path.join(directory, pattern)):
            buttons['ios'] = pattern
            break

    return buttons

def add_app_store_buttons(content, directory):
    """Add clickable app store buttons after Protegus2 app download instruction."""

    # Find which button images are available
    buttons = find_app_store_buttons(directory)

    if not buttons:
        return content  # No button images found

    # Build HTML for available buttons
    button_links = []

    if 'android' in buttons:
        button_links.append(f'''  <a href="https://play.google.com/store/apps/details?id=lt.apps.protegus2" target="_blank" style="display: inline-block; margin-right: 10px;">
    <img src="./{buttons['android']}" alt="Get it on Google Play" style="height:50px;">
  </a>''')

    if 'web' in buttons:
        button_links.append(f'''  <a href="https://www.protegus.app" target="_blank" style="display: inline-block; margin-right: 10px;">
    <img src="./{buttons['web']}" alt="Open Web App" style="height:50px;">
  </a>''')

    if 'ios' in buttons:
        button_links.append(f'''  <a href="https://apps.apple.com/us/app/protegus-2/id1555450252" target="_blank" style="display: inline-block;">
    <img src="./{buttons['ios']}" alt="Download on the App Store" style="height:50px;">
  </a>''')

    if not button_links:
        return content

    buttons_html = '\n<div style="margin: 20px 0; text-align: left;">\n' + '\n'.join(button_links) + '\n</div>\n'

    # Pattern to match the download instruction line
    pattern = r'(1\.\s+Download and launch.*?protegus\.app.*?\)\.)'

    # Add buttons after the download instruction
    content = re.sub(
        pattern,
        r'\1\n' + buttons_html,
        content,
        flags=re.DOTALL
    )

    return content

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 add-app-store-buttons.py <file.md>")
        sys.exit(1)

    filepath = sys.argv[1]
    directory = os.path.dirname(filepath)

    try:
        # Read file
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Add buttons (auto-detect which ones exist)
        modified_content = add_app_store_buttons(content, directory)

        # Write back if changed
        if modified_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(modified_content)
            print(f"✓ Added app store buttons to {filepath}")
        else:
            print(f"✓ No app store buttons or Protegus2 instruction found in {filepath}")

    except Exception as e:
        print(f"Error processing {filepath}: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
