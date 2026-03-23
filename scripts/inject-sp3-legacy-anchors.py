#!/usr/bin/env python3
"""
Inject legacy anchor aliases for known SP3 headings.

Older converted SP3 manuals still link to `#Users_window`. Current markdown
heading ids no longer produce that anchor automatically, so this script inserts
an explicit hidden anchor immediately before the translated heading.
"""

from pathlib import Path
import sys

LEGACY_ANCHOR_HEADINGS = {
    '<a id="Users_window"></a>': {
        '“Users & Reporting” window',
        'Langas „Vartotojai ir pranešimai“',
        'Ventana "Usuarios y Reportes"',
        'Окно „Пользователи и сообщения“',
    },
    '<a id="trikdisconfig-būsenos-juostos-aprašymas"></a>': {
        'TrikdisConfig būsenos juostos aprašymas',
    },
}


def inject_legacy_anchors(lines: list[str]) -> tuple[list[str], bool]:
    updated = list(lines)
    changed = False
    index = 0

    while index < len(updated):
        stripped = updated[index].strip()
        if not stripped.startswith("#"):
            index += 1
            continue

        heading_text = stripped.lstrip("#").strip()
        matching_anchor = None

        for anchor_line, heading_variants in LEGACY_ANCHOR_HEADINGS.items():
            if heading_text in heading_variants:
                matching_anchor = anchor_line
                break

        if matching_anchor is None:
            index += 1
            continue

        if index > 0 and updated[index - 1].strip() == matching_anchor:
            index += 1
            continue

        updated.insert(index, matching_anchor)
        changed = True
        index += 2

    return updated, changed


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: inject-sp3-legacy-anchors.py <markdown-file>", file=sys.stderr)
        return 1

    path = Path(sys.argv[1])
    lines = path.read_text(encoding="utf-8").splitlines()
    updated_lines, changed = inject_legacy_anchors(lines)

    if changed:
        path.write_text("\n".join(updated_lines) + "\n", encoding="utf-8")
        print(f"✓ Injected legacy SP3 anchor alias into {path}")
    else:
        print(f"✓ No SP3 legacy anchor changes needed in {path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
