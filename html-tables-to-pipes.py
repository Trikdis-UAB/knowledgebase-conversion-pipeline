#!/usr/bin/env python3
"""
Convert HTML tables in markdown to pipe tables for human readability.
Processes index.md file in-place.
"""

import re
import sys
from html.parser import HTMLParser

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
        elif tag == "br":
            # Convert <br> to " / " separator
            if self.in_th or self.in_td:
                self.current_cell += " / "
        elif tag == "strong" and (self.in_th or self.in_td):
            # Keep strong tags in cells
            pass

    def handle_endtag(self, tag):
        if tag == "table":
            self.in_table = False
        elif tag == "thead":
            self.in_thead = False
        elif tag == "tbody":
            self.in_tbody = False
        elif tag == "tr":
            # Append row when </tr> is encountered, not after each cell
            if self.current_row and not self.in_thead:
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

    def handle_data(self, data):
        if self.in_th or self.in_td:
            self.current_cell += data

    def get_pipe_table(self):
        if not self.headers:
            return None

        # Build pipe table WITHOUT padding (more compact and readable)
        lines = []

        # Header row (no padding)
        header_line = "| " + " | ".join(self.headers) + " |"
        lines.append(header_line)

        # Separator row (simple dashes)
        sep_line = "|" + "|".join("-" * (len(h) + 2) for h in self.headers) + "|"
        lines.append(sep_line)

        # Data rows (no padding)
        for row in self.rows:
            # Pad row if needed
            while len(row) < len(self.headers):
                row.append("")
            row_line = "| " + " | ".join(str(cell) for cell in row[:len(self.headers)]) + " |"
            lines.append(row_line)

        return "\n".join(lines)

def convert_html_table_to_pipe(html_table):
    """Convert a single HTML table to pipe table format"""
    parser = TableConverter()
    parser.feed(html_table)
    pipe_table = parser.get_pipe_table()
    return pipe_table if pipe_table else html_table

def process_markdown_file(filepath):
    """Process markdown file and convert all HTML tables to pipe tables"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all HTML tables (including <colgroup> and attributes)
    # Match from <table to </table> including newlines
    table_pattern = re.compile(
        r'<table[^>]*>.*?</table>',
        re.DOTALL | re.MULTILINE
    )

    def replace_table(match):
        html_table = match.group(0)
        pipe_table = convert_html_table_to_pipe(html_table)
        return pipe_table if pipe_table != html_table else html_table

    # Replace all HTML tables with pipe tables
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
        print(f"Converted HTML tables to pipe tables in {filepath}")
    else:
        print(f"No HTML tables found in {filepath}")
