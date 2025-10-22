#!/usr/bin/env python3
"""
Convert HTML tables in markdown to Pandoc grid tables.
Grid tables support multi-line cell content without HTML tags.
"""

import re
import sys
from html.parser import HTMLParser
from textwrap import wrap


class TableConverter(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_thead = False
        self.in_tbody = False
        self.in_tr = False
        self.in_th = False
        self.in_td = False
        self.headers = []
        self.rows = []
        self.current_row = []
        self.current_cell = ""

    def handle_starttag(self, tag, attrs):
        if tag == "table":
            self.in_table = True
        elif tag == "thead":
            self.in_thead = True
        elif tag == "tbody":
            self.in_tbody = True
        elif tag == "tr":
            self.in_tr = True
            self.current_row = []
        elif tag == "th":
            self.in_th = True
            self.current_cell = ""
        elif tag == "td":
            self.in_td = True
            self.current_cell = ""

    def handle_endtag(self, tag):
        if tag == "table":
            self.in_table = False
        elif tag == "thead":
            self.in_thead = False
        elif tag == "tbody":
            self.in_tbody = False
        elif tag == "tr":
            if self.in_thead and self.current_row:
                self.headers.extend(self.current_row)
            elif not self.in_thead and self.current_row:
                self.rows.append(self.current_row[:])
            self.current_row = []
            self.in_tr = False
        elif tag == "th":
            self.in_th = False
            self.headers.append(self.current_cell.strip())
            self.current_cell = ""
        elif tag == "td":
            self.in_td = False
            self.current_row.append(self.current_cell.strip())
            self.current_cell = ""
        elif tag in ["p", "br"] and (self.in_th or self.in_td):
            # Add line break for paragraphs and br tags
            if self.current_cell and not self.current_cell.endswith("\n"):
                self.current_cell += "\n"

    def handle_data(self, data):
        if self.in_th or self.in_td:
            self.current_cell += data

    def get_grid_table(self):
        if not self.headers:
            return None

        # Split multi-line cells
        headers_lines = [h.split('\n') for h in self.headers]
        rows_lines = [[cell.split('\n') for cell in row] for row in self.rows]

        # Calculate column widths
        col_widths = []
        num_cols = len(self.headers)

        for col_idx in range(num_cols):
            max_width = 10  # Minimum width

            # Check header width
            for line in headers_lines[col_idx]:
                max_width = max(max_width, len(line.strip()))

            # Check all rows
            for row in rows_lines:
                if col_idx < len(row):
                    for line in row[col_idx]:
                        max_width = max(max_width, len(line.strip()))

            col_widths.append(min(max_width + 2, 40))  # Cap at 40 chars

        # Build grid table
        result = []

        # Top border
        result.append(self._make_border(col_widths, '+', '-', '+'))

        # Headers
        header_height = max(len(lines) for lines in headers_lines)
        for line_idx in range(header_height):
            line_parts = []
            for col_idx, header_lines in enumerate(headers_lines):
                content = header_lines[line_idx] if line_idx < len(header_lines) else ""
                line_parts.append(self._pad_cell(content, col_widths[col_idx]))
            result.append('|' + '|'.join(line_parts) + '|')

        # Header separator
        result.append(self._make_border(col_widths, '+', '=', '+'))

        # Data rows
        for row_lines in rows_lines:
            row_height = max(len(cell_lines) for cell_lines in row_lines)
            for line_idx in range(row_height):
                line_parts = []
                for col_idx, cell_lines in enumerate(row_lines):
                    content = cell_lines[line_idx] if line_idx < len(cell_lines) else ""
                    line_parts.append(self._pad_cell(content, col_widths[col_idx]))
                result.append('|' + '|'.join(line_parts) + '|')

            # Row separator
            result.append(self._make_border(col_widths, '+', '-', '+'))

        return '\n'.join(result)

    def _make_border(self, col_widths, left, fill, right):
        parts = [fill * width for width in col_widths]
        return left + right.join(parts) + left

    def _pad_cell(self, content, width):
        content = content.strip()
        padding = width - len(content)
        return ' ' + content + ' ' * padding


def convert_html_table_to_grid(html_table):
    """Convert a single HTML table to grid table format"""
    parser = TableConverter()
    parser.feed(html_table)
    grid_table = parser.get_grid_table()
    return grid_table if grid_table else html_table


def process_markdown_file(filepath):
    """Process markdown file and convert all HTML tables to grid tables"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all HTML tables
    table_pattern = re.compile(
        r'<table[^>]*>.*?</table>',
        re.DOTALL | re.MULTILINE
    )

    def replace_table(match):
        html_table = match.group(0)
        grid_table = convert_html_table_to_grid(html_table)
        return grid_table if grid_table != html_table else html_table

    # Replace all HTML tables with grid tables
    new_content = table_pattern.sub(replace_table, content)

    # Write back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

    return content != new_content


if __name__ == "__main__":
    if len(sys.argv) > 1:
        filepath = sys.argv[1]
    else:
        filepath = "index.md"

    changed = process_markdown_file(filepath)
    if changed:
        print(f"Converted HTML tables to grid tables in {filepath}")
    else:
        print(f"No HTML tables found in {filepath}")
