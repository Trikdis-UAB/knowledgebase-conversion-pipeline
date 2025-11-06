#!/usr/bin/env python3
"""
Fix malformed tables that are actually numbered lists with empty second column.

Detects tables where:
- First column contains numbered list items or regular text
- Second column is empty
- Converts to proper numbered list or paragraphs
"""

import sys
import re

def is_empty_cell(cell):
    """Check if a table cell is empty or contains only whitespace."""
    cell = cell.strip()
    return cell == "" or cell == "-"

def fix_numbered_list_tables(content):
    """Find and fix tables that should be numbered lists."""

    # Pattern to match pipe tables with 2 columns where second column is empty
    # This pattern handles the case where first row might start with a number
    # Matches: 1. text |  | followed by separator and more rows
    table_pattern = r'(?:^|\n)([^\n]*\|[^\n]*\|\s*\n)\|[-:]+\|[-:]+\|\s*\n((?:\|[^\n]+\|[^\n]*\|\s*\n)+)'

    def process_table(match):
        first_row_line = match.group(1).strip()
        rows_text = match.group(2)

        # Parse first row
        first_row_match = re.match(r'([^\|]+)\|([^\|]*)\|?', first_row_line)
        all_rows = []

        if first_row_match:
            all_rows.append((first_row_match.group(1), first_row_match.group(2)))

        # Parse table rows
        row_pattern = r'\|([^\|]+)\|([^\|]*)\|'
        rows = re.findall(row_pattern, rows_text)
        all_rows.extend(rows)

        # Check if this looks like a numbered list table
        # (most rows have empty second column)
        empty_second_col = 0
        numbered_rows = 0

        for first_col, second_col in all_rows:
            if is_empty_cell(second_col):
                empty_second_col += 1
                # Check if starts with number
                first_col_clean = first_col.strip()
                if re.match(r'^\d+\.', first_col_clean):
                    numbered_rows += 1

        # If 75% have empty second column, it's likely a numbered list table
        if len(all_rows) == 0:
            return match.group(0)  # Keep original

        empty_ratio = empty_second_col / len(all_rows)

        if empty_ratio < 0.75:
            return match.group(0)  # Keep original table

        # Convert to numbered list or paragraphs
        output_lines = []

        # Don't add a header - the first row is part of the numbered list

        list_counter = 1
        for first_col, second_col in all_rows:
            first_col = first_col.strip()

            if not first_col:
                continue  # Skip empty rows

            # Check if already starts with a number
            num_match = re.match(r'^(\d+)\.\s*(.+)$', first_col)
            if num_match:
                # It's already numbered - keep the number
                output_lines.append(f"{first_col}")
            else:
                # Not numbered - add number
                output_lines.append(f"{list_counter}. {first_col}")
                list_counter += 1

        return "\n" + "\n\n".join(output_lines) + "\n"

    # Process all matching tables
    content = re.sub(table_pattern, process_table, content, flags=re.MULTILINE)

    return content

def main(filename):
    """Process a markdown file."""
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()

        # Fix numbered list tables
        content = fix_numbered_list_tables(content)

        with open(filename, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"Fixed numbered list tables in {filename}")

    except Exception as e:
        print(f"Error processing {filename}: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: fix-numbered-list-tables.py <markdown_file>", file=sys.stderr)
        sys.exit(1)

    main(sys.argv[1])
