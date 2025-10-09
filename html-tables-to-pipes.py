#!/usr/bin/env python3
"""
Convert HTML tables in markdown to pipe tables for human readability.
Processes index.md file in-place.
Flattens rowspan cells by duplicating content across spanned rows.
"""

import re
import sys
from html.parser import HTMLParser
from html import unescape

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
            # Keep <br> tags for rowspan merging
            if self.in_th or self.in_td:
                self.current_cell += "<br>"
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
            # Normalize whitespace: replace multiple spaces/newlines with single space
            cell_content = ' '.join(self.current_cell.split())
            self.headers.append(cell_content)
            self.current_cell = ""
        elif tag == "td":
            self.in_td = False
            # Normalize whitespace: replace multiple spaces/newlines with single space
            cell_content = ' '.join(self.current_cell.split())
            self.current_row.append(cell_content)
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

def flatten_rowspan_html(html_table):
    """
    Flatten rowspan cells by merging content with <br> tags.
    For manufacturer tables, this avoids repeating names like PARADOX®.
    """
    from html.parser import HTMLParser

    class RowspanParser(HTMLParser):
        def __init__(self):
            super().__init__()
            self.header_rows = []
            self.body_rows = []
            self.current_row = []
            self.current_cell = None
            self.in_cell = False
            self.in_thead = False
            self.in_tbody = False

        def handle_starttag(self, tag, attrs):
            if tag == 'thead':
                self.in_thead = True
            elif tag == 'tbody':
                self.in_tbody = True
            elif tag == 'tr':
                self.current_row = []
            elif tag in ('td', 'th'):
                self.in_cell = True
                attrs_dict = dict(attrs)
                self.current_cell = {
                    'tag': tag,
                    'rowspan': int(attrs_dict.get('rowspan', 1)),
                    'content_parts': []
                }
            elif self.in_cell:
                # Preserve <u> tags for underlining
                if tag == 'u':
                    self.current_cell['content_parts'].append('<u>')
                else:
                    # Capture other inner HTML tags, preserve <br> tags
                    attrs_str = ' '.join(f'{k}="{v}"' for k, v in attrs) if attrs else ''
                    tag_str = f'<{tag}' + (f' {attrs_str}' if attrs_str else '') + '>'
                    self.current_cell['content_parts'].append(tag_str)

        def handle_endtag(self, tag):
            if tag == 'thead':
                self.in_thead = False
            elif tag == 'tbody':
                self.in_tbody = False
            elif tag in ('td', 'th'):
                self.current_row.append(self.current_cell)
                self.in_cell = False
                self.current_cell = None
            elif tag == 'tr':
                if self.current_row:
                    if self.in_thead:
                        self.header_rows.append(self.current_row)
                    else:
                        self.body_rows.append(self.current_row)
            elif self.in_cell:
                self.current_cell['content_parts'].append(f'</{tag}>')

        def handle_data(self, data):
            if self.in_cell:
                self.current_cell['content_parts'].append(data)

    # Parse the table
    parser = RowspanParser()
    try:
        parser.feed(html_table)
    except:
        # If parsing fails, return original
        return html_table

    if not parser.header_rows and not parser.body_rows:
        return html_table

    def merge_rowspan_rows(rows):
        """Merge rowspan cells with <br> tags instead of duplicating"""
        if not rows:
            return []

        # Track rows that should be skipped (merged into rowspan)
        skip_rows = set()

        # First pass: identify rowspan cells and what rows they affect
        rowspan_cells = []
        for row_idx, row in enumerate(rows):
            col_offset = 0
            for cell_idx, cell in enumerate(row):
                if cell and cell.get('rowspan', 1) > 1:
                    rowspan_cells.append({
                        'row': row_idx,
                        'col': cell_idx + col_offset,
                        'span': cell['rowspan']
                    })
                    # Mark the rows that will be merged
                    for r in range(1, cell['rowspan']):
                        skip_rows.add(row_idx + r)

        # Build result grid
        grid = []

        for row_idx, row in enumerate(rows):
            if row_idx in skip_rows:
                # This row's content will be merged into a rowspan cell
                continue

            # Check if this row starts with a rowspan cell
            has_rowspan = any(rc['row'] == row_idx and rc['col'] == 0
                            for rc in rowspan_cells)

            if has_rowspan:
                # This row has a rowspan cell - collect content from subsequent rows
                rowspan_info = next(rc for rc in rowspan_cells
                                   if rc['row'] == row_idx and rc['col'] == 0)

                # First cell is the rowspan cell (manufacturer)
                manufacturer = ''.join(row[0]['content_parts'])

                # Collect model content from this row and subsequent rows
                models = []

                # Current row model (second cell)
                if len(row) > 1:
                    models.append(''.join(row[1]['content_parts']))

                # Subsequent rows models
                for r in range(1, rowspan_info['span']):
                    next_row_idx = row_idx + r
                    if next_row_idx < len(rows) and rows[next_row_idx]:
                        # Get first cell from subsequent row (it's the model)
                        next_row = rows[next_row_idx]
                        if next_row and len(next_row) > 0:
                            models.append(''.join(next_row[0]['content_parts']))

                # Create merged row with manufacturer and joined models
                merged_row = [
                    {'tag': row[0]['tag'], 'content': manufacturer},
                    {'tag': row[1]['tag'] if len(row) > 1 else 'td',
                     'content': '<br>'.join(models)}
                ]
                grid.append(merged_row)
            else:
                # Normal row without rowspan
                grid_row = []
                for cell in row:
                    if cell:
                        content = ''.join(cell['content_parts'])
                        grid_row.append({
                            'tag': cell['tag'],
                            'content': content
                        })
                grid.append(grid_row)

        return grid

    # Process header and body separately
    header_grid = merge_rowspan_rows(parser.header_rows) if parser.header_rows else []
    body_grid = merge_rowspan_rows(parser.body_rows) if parser.body_rows else []

    # Rebuild HTML with merged rowspan cells
    lines = ['<table>']

    if header_grid:
        lines.append('<thead>')
        for row in header_grid:
            lines.append('<tr>')
            for cell in row:
                if cell and not cell.get('skip'):
                    lines.append(f"<{cell['tag']}>{cell['content']}</{cell['tag']}>")
            lines.append('</tr>')
        lines.append('</thead>')

    if body_grid:
        lines.append('<tbody>')
        for row in body_grid:
            # Skip rows that only contain "skip" markers
            has_content = any(cell and not cell.get('skip') for cell in row if cell)
            if has_content:
                lines.append('<tr>')
                for cell in row:
                    if cell and not cell.get('skip'):
                        lines.append(f"<{cell['tag']}>{cell['content']}</{cell['tag']}>")
                lines.append('</tr>')
        lines.append('</tbody>')

    lines.append('</table>')

    return '\n'.join(lines)


def convert_html_table_to_pipe(html_table):
    """Convert a single HTML table to pipe table format"""
    # Flatten rowspan first if present
    if 'rowspan=' in html_table:
        html_table = flatten_rowspan_html(html_table)

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
