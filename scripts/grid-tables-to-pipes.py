#!/usr/bin/env python3
"""
Convert Pandoc grid tables to pipe tables with <br> tags for multi-line content.

Grid tables are incompatible with MkDocs Python-Markdown processor.
This script converts them to standard pipe tables with HTML <br> tags for line breaks.
"""

import re
import sys

def parse_grid_table(lines):
    """Parse a grid table and extract cell contents."""
    # Find separator lines (those with + and -)
    separator_indices = []
    for i, line in enumerate(lines):
        if re.match(r'^\+[-=]+\+', line):
            separator_indices.append(i)

    if len(separator_indices) < 2:
        return None

    # Determine column positions from first separator
    first_sep = lines[separator_indices[0]]
    col_positions = [m.start() for m in re.finditer(r'\+', first_sep)]

    if len(col_positions) < 2:
        return None

    # Extract rows between separators
    rows = []
    for i in range(len(separator_indices) - 1):
        start = separator_indices[i] + 1
        end = separator_indices[i + 1]

        # Combine all lines in this row
        row_lines = lines[start:end]
        if not row_lines:
            continue

        # Extract cells for this row
        cells = []
        for col_idx in range(len(col_positions) - 1):
            left = col_positions[col_idx]
            right = col_positions[col_idx + 1]

            # Extract content from all lines in this cell
            cell_content = []
            for line in row_lines:
                if left < len(line) and right <= len(line):
                    cell_text = line[left+1:right].rstrip('|').strip()
                    if cell_text:
                        cell_content.append(cell_text)

            cells.append(cell_content)

        if cells:
            rows.append(cells)

    # Determine if first row is header (line with === after it)
    has_header = False
    if len(separator_indices) > 1:
        header_sep = lines[separator_indices[1]]
        if '=' in header_sep:
            has_header = True

    return {
        'rows': rows,
        'has_header': has_header
    }

def convert_grid_to_pipe(table_data):
    """Convert parsed grid table to pipe table format."""
    if not table_data or not table_data['rows']:
        return None

    rows = table_data['rows']
    has_header = table_data['has_header']

    # Determine number of columns
    num_cols = max(len(row) for row in rows)

    # Build pipe table
    lines = []

    for row_idx, row in enumerate(rows):
        # Pad row to have correct number of columns
        while len(row) < num_cols:
            row.append([])

        # Join multi-line cells with <br> tags
        pipe_cells = []
        for cell in row:
            # Join lines with <br>, use <br><br> for empty lines (paragraph breaks)
            cell_text = '<br>'.join(cell) if cell else ''
            # Replace multiple consecutive <br> with <br><br> for paragraph breaks
            cell_text = re.sub(r'(<br>){2,}', '<br><br>', cell_text)
            pipe_cells.append(cell_text)

        # Build pipe table row
        lines.append('| ' + ' | '.join(pipe_cells) + ' |')

        # Add separator after header
        if row_idx == 0 and has_header:
            separators = ['---' for _ in range(num_cols)]
            lines.append('| ' + ' | '.join(separators) + ' |')

    return '\n'.join(lines)

def process_file(filepath):
    """Process a markdown file and convert all grid tables to pipe tables."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.split('\n')
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Check if this line starts a grid table
        if re.match(r'^\+[-=]+\+', line):
            # Find the end of the grid table
            table_lines = [line]
            j = i + 1
            while j < len(lines):
                table_lines.append(lines[j])
                if re.match(r'^\+[-=]+\+', lines[j]) and j > i:
                    # Check if next line is also part of table
                    if j + 1 < len(lines) and re.match(r'^[|+]', lines[j + 1]):
                        j += 1
                        continue
                    else:
                        # End of table
                        break
                j += 1

            # Try to parse and convert this table
            table_data = parse_grid_table(table_lines)
            if table_data:
                pipe_table = convert_grid_to_pipe(table_data)
                if pipe_table:
                    result.append(pipe_table)
                    i = j + 1
                    continue

        # Not a grid table or conversion failed, keep original line
        result.append(line)
        i += 1

    # Write result
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(result))

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <markdown_file>")
        sys.exit(1)

    process_file(sys.argv[1])
