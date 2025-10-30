#!/usr/bin/env python3
"""
add-app-store-buttons.py
Adds clickable app store buttons after "Download and launch the Protegus2 app" text
Automatically detects which button images are available (image16-21)
If no buttons found, copies standard buttons from app-store-buttons/ directory
"""

import sys
import re
import os
import shutil

def find_app_store_buttons(directory):
    """Find app store button images in the directory.

    Only considers images < 15KB to be app store buttons (not random manual images).
    Returns dict with button types and their image filenames.
    """
    buttons = {}

    # Check for various button image patterns
    # Pattern: image16/19 = Google Play, image17/20 = App Store, image18/21 = Web
    android_patterns = ['image16.png', 'image19.png']
    ios_patterns = ['image17.png', 'image20.png']
    web_patterns = ['image18.png', 'image21.png']

    # Only consider small images (< 15KB) as app store buttons
    # Manual images are typically much larger (50KB+)
    MAX_BUTTON_SIZE = 15 * 1024  # 15 KB

    for pattern in android_patterns:
        filepath = os.path.join(directory, pattern)
        if os.path.exists(filepath) and os.path.getsize(filepath) < MAX_BUTTON_SIZE:
            buttons['android'] = pattern
            break

    for pattern in web_patterns:
        filepath = os.path.join(directory, pattern)
        if os.path.exists(filepath) and os.path.getsize(filepath) < MAX_BUTTON_SIZE:
            buttons['web'] = pattern
            break

    for pattern in ios_patterns:
        filepath = os.path.join(directory, pattern)
        if os.path.exists(filepath) and os.path.getsize(filepath) < MAX_BUTTON_SIZE:
            buttons['ios'] = pattern
            break

    return buttons

def copy_standard_buttons(directory, script_dir):
    """Copy standard app store button images with unique names.

    Returns dict with button filenames if successful.
    """
    standard_buttons_dir = os.path.join(script_dir, 'app-store-buttons')

    # Check if standard buttons directory exists
    if not os.path.exists(standard_buttons_dir):
        return {}

    buttons = {}
    button_mapping = {
        'android': ('protegus-android.png', 'protegus-android.png'),
        'ios': ('protegus-ios.png', 'protegus-ios.png'),
        'web': ('protegus-web.png', 'protegus-web.png')
    }

    for button_type, (source_name, dest_name) in button_mapping.items():
        source_path = os.path.join(standard_buttons_dir, source_name)
        dest_path = os.path.join(directory, dest_name)

        if os.path.exists(source_path):
            shutil.copy2(source_path, dest_path)
            buttons[button_type] = dest_name

    return buttons

def add_app_store_buttons(content, directory, script_dir):
    """Add clickable app store buttons after Protegus2 app download instruction.

    Always uses standard protegus-*.png buttons with clickable links.
    Replaces any existing placeholder images.
    """

    # Always copy/ensure standard buttons are available
    buttons = copy_standard_buttons(directory, script_dir)

    if not buttons:
        return content  # No standard buttons available

    # Build HTML for clickable buttons (always all three)
    buttons_html = '''
<div style="margin: 20px 0; text-align: left;">
  <a href="https://play.google.com/store/apps/details?id=lt.apps.protegus2" target="_blank" style="display: inline-block; margin-right: 10px;">
    <img src="./protegus-android.png" alt="Get it on Google Play" style="height:50px;">
  </a>
  <a href="https://www.protegus.app" target="_blank" style="display: inline-block; margin-right: 10px;">
    <img src="./protegus-web.png" alt="Open Web App" style="height:50px;">
  </a>
  <a href="https://apps.apple.com/us/app/protegus-2/id1555450252" target="_blank" style="display: inline-block;">
    <img src="./protegus-ios.png" alt="Download on the App Store" style="height:50px;">
  </a>
</div>'''

    # Language-specific patterns for download instructions
    # Add more languages here as needed
    # Patterns must end with a period or bracket to ensure we match only the download line
    patterns = [
        # English variations - match the complete sentence ending with period or parenthesis
        r'(Download and launch the Protegus2 app[^\n]*\)\.)',
        r'(Download and install Protegus2 mobile app[^\n]*\.)',

        # Lithuanian (add when converting LT manuals)
        # r'(Atsisiųskite.*?Protegus2.*?\)\.)',

        # Spanish (add when converting ES manuals)
        # r'(Descargue.*?Protegus2.*?\)\.)',

        # Russian (add when converting RU manuals)
        # r'(Загрузите.*?Protegus2.*?\)\.)',
    ]

    # Try each pattern
    for pattern in patterns:
        # Strategy 1: Look for download sentence + image (e.g., SP3 manual)
        pattern_with_image = pattern + r'\n\n<img[^>]+src="[^"]*"[^>]*>'

        if re.search(pattern_with_image, content, re.IGNORECASE):
            # Replace: keep the text, replace the image with clickable buttons
            content = re.sub(
                pattern_with_image,
                r'\1' + buttons_html,
                content,
                count=1,  # Only first occurrence
                flags=re.IGNORECASE
            )
            return content

        # Strategy 2: Look for download sentence without image (e.g., GATOR manual)
        # Insert buttons after the sentence
        if re.search(pattern, content, re.IGNORECASE):
            content = re.sub(
                pattern,
                r'\1' + buttons_html,
                content,
                count=1,  # Only first occurrence
                flags=re.IGNORECASE
            )
            return content

    return content

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 add-app-store-buttons.py <file.md>")
        sys.exit(1)

    filepath = sys.argv[1]
    directory = os.path.dirname(filepath)
    script_dir = os.path.dirname(os.path.abspath(__file__))

    try:
        # Read file
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Add buttons (auto-detect which ones exist or use standard buttons)
        modified_content = add_app_store_buttons(content, directory, script_dir)

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
