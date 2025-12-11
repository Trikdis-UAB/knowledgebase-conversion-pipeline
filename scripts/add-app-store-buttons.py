#!/usr/bin/env python3
"""Ensure Protegus button assets exist for the manual output folder."""

import os
import shutil
import sys
from pathlib import Path

BUTTONS = {
    "protegus-android.png": "app-store-buttons/protegus-android.png",
    "protegus-ios.png": "app-store-buttons/protegus-ios.png",
    "protegus-web.png": "app-store-buttons/protegus-web.png",
}


def ensure_buttons(target_dir: Path, repo_root: Path) -> bool:
    """Copy Protegus button assets from repo root into target_dir."""
    changed = False
    for dest_name, rel_source in BUTTONS.items():
        source_path = repo_root / rel_source
        dest_path = target_dir / dest_name
        if not source_path.exists():
            continue
        try:
            if not dest_path.exists() or source_path.stat().st_mtime > dest_path.stat().st_mtime:
                shutil.copy2(source_path, dest_path)
                changed = True
        except OSError:
            # Non-fatal; keep going.
            pass
    return changed


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: python3 add-app-store-buttons.py <file.md>")
        sys.exit(1)

    md_path = Path(sys.argv[1]).resolve()
    target_dir = md_path.parent
    repo_root = Path(__file__).resolve().parent.parent

    if ensure_buttons(target_dir, repo_root):
        print(f"✓ Ensured Protegus button assets in {target_dir}")
    else:
        print(f"✓ Protegus button assets already present in {target_dir}")


if __name__ == "__main__":
    main()
