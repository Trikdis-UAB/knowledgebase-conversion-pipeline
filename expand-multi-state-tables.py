#!/usr/bin/env python3
"""
Expand Multi-State Tables to Separate Rows

This script finds tables with multi-state cells (cells with <br> tags indicating
multiple states/values) and expands them into separate rows for better readability.

Example transformation:
| Indicator | Light status | Description |
| NETWORK LTE | Off <br> Yellow blinking | No network <br> Searching |

Becomes:
| Indicator | Light status | Description |
| NETWORK LTE | Off | No network |
| NETWORK LTE | Yellow blinking | Searching |

This creates pure markdown tables without HTML tags, making them more readable
and maintainable.
"""

import sys
import re


def split_cell_content(cell):
    """
    Split cell content by <br> tags and clean up whitespace.

    Args:
        cell: String containing cell content, possibly with <br> tags

    Returns:
        List of individual values from the cell
    """
    # Split by <br> or <br/> or <br /> tags
    parts = re.split(r'\s*<br\s*/?>\s*', cell.strip())
    # Clean up each part and remove empty strings
    return [part.strip() for part in parts if part.strip()]


def has_multi_state_cells(row):
    """
    Check if a table row has any cells with <br> tags.

    Args:
        row: String containing a table row

    Returns:
        True if the row contains <br> tags, False otherwise
    """
    return '<br' in row


def is_table_separator(line):
    """Check if a line is a table separator (|---|---|)."""
    return bool(re.match(r'^\s*\|[\s\-:|]+\|\s*$', line))


def is_table_row(line):
    """Check if a line is a table row."""
    return line.strip().startswith('|') and line.strip().endswith('|')


def expand_table_row(row, is_first_expansion=True):
    """
    Expand a table row with multi-state cells into multiple rows.

    Args:
        row: String containing a table row with <br> tags
        is_first_expansion: If True, this is the first expanded row (keep first column value)

    Returns:
        List of expanded row strings
    """
    # Split the row into cells
    cells = [cell.strip() for cell in row.split('|')]
    # Remove empty first/last elements from split
    cells = [c for c in cells if c]

    if not cells:
        return [row]

    # Split each cell by <br> tags
    split_cells = [split_cell_content(cell) for cell in cells]

    # Find the maximum number of states in any cell
    max_states = max(len(cell_parts) for cell_parts in split_cells)

    if max_states <= 1:
        # No multi-state cells, return as-is
        return [row]

    # Generate expanded rows
    expanded_rows = []

    for i in range(max_states):
        new_cells = []
        for col_idx, cell_parts in enumerate(split_cells):
            if len(cell_parts) > i:
                # This cell has a value for this state
                new_cells.append(cell_parts[i])
            elif len(cell_parts) == 1:
                # This cell has only one value - repeat it for all states (usually the first column)
                new_cells.append(cell_parts[0])
            else:
                # This cell has fewer values than the max - leave empty
                new_cells.append('')

        # Create the expanded row with newline
        expanded_row = '| ' + ' | '.join(new_cells) + ' |\n'
        expanded_rows.append(expanded_row)

    return expanded_rows


def process_file(filepath):
    """
    Process a markdown file to expand multi-state tables.

    Args:
        filepath: Path to the markdown file
    """
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Error reading file: {e}", file=sys.stderr)
        return

    processed_lines = []
    in_table = False
    table_lines = []
    changes_made = False

    i = 0
    while i < len(lines):
        line = lines[i]

        if is_table_row(line):
            if not in_table:
                # Start of a table
                in_table = True
                table_lines = [line]
            else:
                # Inside a table
                table_lines.append(line)
        else:
            if in_table:
                # End of table - process it
                expanded_table = process_table(table_lines)
                if expanded_table != table_lines:
                    changes_made = True
                    print(f"Expanded multi-state table at line {len(processed_lines) + 1}", file=sys.stderr)
                processed_lines.extend(expanded_table)
                in_table = False
                table_lines = []

            processed_lines.append(line)

        i += 1

    # Process any remaining table
    if in_table and table_lines:
        expanded_table = process_table(table_lines)
        if expanded_table != table_lines:
            changes_made = True
            print(f"Expanded multi-state table at line {len(processed_lines) + 1}", file=sys.stderr)
        processed_lines.extend(expanded_table)

    if changes_made:
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(processed_lines)
            print(f"Expanded multi-state tables in {filepath}", file=sys.stderr)
        except Exception as e:
            print(f"Error writing file: {e}", file=sys.stderr)
    else:
        print(f"No multi-state tables found in {filepath}", file=sys.stderr)


def process_table(table_lines):
    """
    Process a complete table to expand multi-state cells.

    Args:
        table_lines: List of strings representing table rows

    Returns:
        List of processed table rows (potentially expanded)
    """
    if len(table_lines) < 2:
        return table_lines

    # Check if this table has multi-state cells
    has_multi_state = any(has_multi_state_cells(line) for line in table_lines[2:])  # Skip header and separator

    if not has_multi_state:
        return table_lines

    processed_table = []

    # Keep header row
    processed_table.append(table_lines[0])

    # Keep separator row
    if len(table_lines) > 1 and is_table_separator(table_lines[1]):
        processed_table.append(table_lines[1])
        data_start = 2
    else:
        data_start = 1

    # Process data rows
    for row in table_lines[data_start:]:
        if has_multi_state_cells(row):
            # Expand this row
            expanded = expand_table_row(row)
            processed_table.extend(expanded)
        else:
            # Keep as-is
            processed_table.append(row)

    return processed_table


def main():
    if len(sys.argv) != 2:
        print("Usage: expand-multi-state-tables.py <markdown-file>", file=sys.stderr)
        sys.exit(1)

    filepath = sys.argv[1]
    process_file(filepath)


if __name__ == '__main__':
    main()
