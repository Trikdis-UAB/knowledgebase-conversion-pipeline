#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONVERT_SCRIPT="${SCRIPT_DIR}/convert-single.sh"

if [ ! -f "$CONVERT_SCRIPT" ]; then
  echo "Missing ${CONVERT_SCRIPT}" >&2
  exit 1
fi

required_patterns=(
  "KEYPAD_MODE"
  "convert-keypad-layout.lua"
  "flatten-layout-tables.lua"
  "promote-keypad-headings.lua"
  "scale-inline-icons.lua"
  "rewrite_keypad_tables.py"
)

for pattern in "${required_patterns[@]}"; do
  if ! rg -q "$pattern" "$CONVERT_SCRIPT"; then
    echo "Missing pattern '${pattern}' in ${CONVERT_SCRIPT}" >&2
    exit 1
  fi
done

required_files=(
  "${ROOT_DIR}/lua-filters/collapse-spacer-columns.lua"
  "${ROOT_DIR}/lua-filters/convert-keypad-layout.lua"
  "${ROOT_DIR}/lua-filters/flatten-layout-tables.lua"
  "${ROOT_DIR}/lua-filters/promote-keypad-headings.lua"
  "${ROOT_DIR}/lua-filters/scale-inline-icons.lua"
  "${SCRIPT_DIR}/rewrite_keypad_tables.py"
)

for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "Missing file ${file}" >&2
    exit 1
  fi
done

echo "Keypad mode checks passed."
