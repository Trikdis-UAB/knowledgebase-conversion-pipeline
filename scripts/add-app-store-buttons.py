#!/usr/bin/env python3
"""Ensure Protegus button assets exist for the manual output folder."""

import os
import shutil
import sys

BUTTONS = {
    "protegus-android.png": "app-store-buttons/protegus-android.png",
    "protegus-ios.png": "app-store-buttons/protegus-ios.png",
    "protegus-web.png": "app-store-buttons/protegus-web.png",
}


def ensure_buttons(target_dir: str, script_dir: str) -> bool:
    changed = False
    for dest_name, rel_source in BUTTONS.items():
        source_path = os.path.join(script_dir, rel_source)
        dest_path = os.path.join(target_dir, dest_name)
        if not os.path.exists(source_path):
            continue
        try:
            if not os.path.exists(dest_path) or os.path.getmtime(source_path) > os.path.getmtime(dest_path):
                shutil.copy2(source_path, dest_path)
                changed = True
        except OSError:
            pass
    return changed


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: python3 add-app-store-buttons.py <file.md>")
        sys.exit(1)

    md_path = sys.argv[1]
    target_dir = os.path.dirname(md_path)
    script_dir = os.path.dirname(os.path.abspath(__file__))

    if ensure_buttons(target_dir, script_dir):
        print(f"✓ Ensured Protegus button assets in {target_dir}")
    else:
        print(f"✓ Protegus button assets already present in {target_dir}")


if __name__ == "__main__":
    main()
