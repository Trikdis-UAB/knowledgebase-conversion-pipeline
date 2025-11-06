#!/usr/bin/env python3
"""
Fix tables that are actually instruction steps with images.

This handles the specific pattern where:
- A header row contains introductory text
- Each subsequent row contains either:
  - A numbered step (1., 2., etc.) in column 1, empty column 2
  - An image or content without number

Converts to:
- Introductory paragraph
- Properly numbered list with images between steps

Example input:
| Launch Protegus2 application on your phone. Log in with your user name and password. |  |
|--------------------------------------------------------------------------------------|--|
| 1. Press "Settings". | (image) |
| 2. Press "System". |  |
| (image) |  |

Example output:
Launch Protegus2 application on your phone. Log in with your user name and password.

1. Press "Settings".

(image)

2. Press "System".

(image)
"""

import sys
import re


def is_likely_instruction_table(lines, start_idx):
    """
    Detect if this table looks like instruction steps.

    Characteristics:
    - 2 columns
    - First row has substantial text (introduction)
    - Subsequent rows have numbered steps (1., 2., etc.)
    - Second column mostly empty
    """
    # Check if we have enough lines for a table
    if start_idx + 3 >= len(lines):
        return False

    header_line = lines[start_idx].strip()
    separator_line = lines[start_idx + 1].strip()

    # Must be a 2-column table
    if separator_line.count('|') < 3:  # At least |---|---|
        return False

    # Check if separator has exactly 2 columns
    parts = [p.strip() for p in separator_line.split('|')]
    non_empty = [p for p in parts if p]
    if len(non_empty) != 2:
        return False

    # Check subsequent rows for numbered steps pattern
    numbered_rows = 0
    rows_checked = 0

    for i in range(start_idx + 2, min(start_idx + 10, len(lines))):
        line = lines[i].strip()
        if not line.startswith('|'):
            break

        rows_checked += 1
        # Extract first column content
        match = re.match(r'\|\s*([^|]*?)\s*\|', line)
        if match:
            first_col = match.group(1).strip()
            # Check if starts with number
            if re.match(r'^\d+\.', first_col):
                numbered_rows += 1

    # If we have at least 2 numbered rows out of the first few rows, it's likely an instruction table
    return rows_checked >= 2 and numbered_rows >= 2


def extract_table_rows(lines, start_idx):
    """Extract all rows from a pipe table starting at start_idx."""
    rows = []
    i = start_idx

    while i < len(lines):
        line = lines[i].strip()
        if not line.startswith('|'):
            break

        # Skip separator row
        if i == start_idx + 1:
            i += 1
            continue

        # Parse the row
        parts = line.split('|')
        # Remove empty first and last parts from split
        if len(parts) > 0 and parts[0].strip() == '':
            parts = parts[1:]
        if len(parts) > 0 and parts[-1].strip() == '':
            parts = parts[:-1]

        # Get first two columns
        if len(parts) >= 2:
            col1 = parts[0].strip()
            col2 = parts[1].strip() if len(parts) > 1 else ''
            rows.append((col1, col2))

        i += 1

    return rows, i


def convert_instruction_table(lines, start_idx):
    """Convert an instruction table to proper formatted steps with images."""
    rows, end_idx = extract_table_rows(lines, start_idx)

    if not rows:
        return None, start_idx

    output = []

    # First row is the header/introduction
    if rows[0][0]:
        intro = rows[0][0].strip()
        # Remove any markdown table formatting
        intro = intro.replace('\\|', '|')
        output.append(intro)
        output.append('')  # Blank line after intro

    # Process subsequent rows
    for col1, col2 in rows[1:]:
        # Check if this is a numbered step
        num_match = re.match(r'^(\d+)\.\s*(.+)$', col1)

        if num_match:
            # It's a numbered step
            output.append(f"{num_match.group(1)}. {num_match.group(2)}")
        elif col1:
            # Content without number - could be image or additional text
            output.append(col1)

        # Add second column content if not empty
        if col2 and col2 != '':
            output.append('')  # Blank line before
            output.append(col2)

        # Add blank line after each step/item
        if col1 or col2:
            output.append('')

    # Remove trailing blank lines
    while output and output[-1] == '':
        output.pop()

    return output, end_idx


def fix_instruction_step_tables(content):
    """Find and fix instruction step tables in markdown content."""
    lines = content.split('\n')
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Check if this line starts a table
        if line.strip().startswith('|') and i + 1 < len(lines):
            next_line = lines[i + 1].strip()

            # Check if next line is a table separator
            if re.match(r'^\|[-:]+\|[-:]+\|', next_line):
                # This is a table - check if it's an instruction table
                if is_likely_instruction_table(lines, i):
                    # Convert it
                    converted, new_idx = convert_instruction_table(lines, i)
                    if converted:
                        result.extend(converted)
                        i = new_idx
                        continue

        # Not an instruction table, keep the line
        result.append(line)
        i += 1

    return '\n'.join(result)


def main(filename):
    """Process a markdown file."""
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()

        # Fix instruction step tables
        content = fix_instruction_step_tables(content)

        with open(filename, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"Fixed instruction step tables in {filename}")

    except Exception as e:
        print(f"Error processing {filename}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: fix-instruction-step-tables.py <markdown_file>", file=sys.stderr)
        sys.exit(1)

    main(sys.argv[1])
