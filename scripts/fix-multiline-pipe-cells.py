#!/usr/bin/env python3
"""
Fix pipe tables with multi-line cell content.

Problem:
Pipe tables in markdown cannot have cells spanning multiple lines:
| Col1 | Col2 |
|------|------|
| Text | Line 1
Line 2
Line 3 |

This breaks table rendering in MkDocs.

Solution:
Convert multi-line cells to single-line with <br> tags:
| Col1 | Col2 |
|------|------|
| Text | Line 1<br>Line 2<br>Line 3 |
"""

import sys
import re


def fix_multiline_pipe_tables(content):
    """
    Find pipe tables and fix cells that have content on multiple lines.
    """
    lines = content.split('\n')
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Check if this line starts a pipe table
        if line.strip().startswith('|'):
            # Look ahead up to 10 lines to find the separator row
            separator_index = None
            for look_ahead in range(1, min(11, len(lines) - i)):
                potential_sep = lines[i + look_ahead].strip()
                if re.match(r'^\|[\s\-:|]+\|[\s\-:|]*$', potential_sep):
                    separator_index = i + look_ahead
                    break
                # Stop if we hit a heading or major break
                if (potential_sep.startswith('#') or
                    potential_sep.startswith('!') or
                    potential_sep.startswith('<') or
                    potential_sep.startswith('***')):
                    break

            # If we found a separator, this is a table
            if separator_index:
                # This is a table - collect header rows (everything before separator)
                table_lines = []
                header_rows = []

                # Collect all lines from current position to separator
                for j in range(i, separator_index):
                    header_rows.append(lines[j])

                # Merge header rows into single row with <br> tags
                merged_header = header_rows[0]  # Start with first header line
                for j in range(1, len(header_rows)):
                    # Append continuation lines with <br>
                    merged_header = merged_header.rstrip() + '<br>' + header_rows[j].strip()

                table_lines.append(merged_header)  # Add merged header
                table_lines.append(lines[separator_index])  # Add separator
                i = separator_index + 1  # Move past separator

                # Collect all rows until we hit a non-table line
                # Track if we're inside a multi-line cell
                in_multiline_cell = False

                while i < len(lines):
                    curr_line = lines[i].strip()

                    # Check if this looks like a table row (starts with |)
                    if curr_line.startswith('|'):
                        table_lines.append(lines[i])
                        # Check if this row ends with | (closed cell) or not (open cell)
                        in_multiline_cell = not curr_line.rstrip().endswith('|')
                        i += 1
                    # Empty line - could be within a multi-line cell
                    elif not curr_line and in_multiline_cell:
                        # Skip empty lines within cells (add as <br> if needed)
                        table_lines[-1] += '<br>'
                        i += 1
                    # Check if this is continuation of previous cell (no leading |, not a heading)
                    elif (in_multiline_cell or (table_lines and curr_line and
                          not curr_line.startswith('#') and
                          not curr_line.startswith('##') and
                          not curr_line.startswith('>')and
                          not curr_line.startswith('!') and
                          not curr_line.startswith('<'))):
                        # This is a continuation line - append to previous table line with <br>
                        table_lines[-1] += '<br>' + lines[i].strip()
                        # Check if we're still in a multi-line cell (line doesn't end with |)
                        in_multiline_cell = not lines[i].rstrip().endswith('|')
                        i += 1
                    else:
                        # Start of new section - end of table
                        break

                # Process the collected table to ensure all cells are valid
                fixed_table = fix_table_structure(table_lines)
                result.extend(fixed_table)
                continue

        # Not a table line
        result.append(line)
        i += 1

    return '\n'.join(result)


def fix_table_structure(table_lines):
    """
    Ensure each row has the correct number of pipes and handle rowspan.
    """
    if len(table_lines) < 2:
        return table_lines

    # Count columns from separator row
    separator = table_lines[1]
    num_cols = separator.count('|') - 1

    fixed_lines = []

    for idx, line in enumerate(table_lines):
        if idx == 1:  # Separator row - keep as is
            fixed_lines.append(line)
            continue

        # Count pipes in this row
        pipe_count = line.count('|')

        # If the row has the correct number of pipes, keep it
        if pipe_count == num_cols + 1:
            fixed_lines.append(line)
        else:
            # Try to fix by ensuring the line ends with |
            if not line.rstrip().endswith('|'):
                line = line.rstrip() + ' |'
            fixed_lines.append(line)

    return fixed_lines


def main(filename):
    """Process a markdown file."""
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()

        # Fix multiline pipe table cells
        content = fix_multiline_pipe_tables(content)

        with open(filename, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"Fixed multiline pipe table cells in {filename}")

    except Exception as e:
        print(f"Error processing {filename}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: fix-multiline-pipe-cells.py <markdown_file>", file=sys.stderr)
        sys.exit(1)

    main(sys.argv[1])
