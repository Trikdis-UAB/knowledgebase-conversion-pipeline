#!/usr/bin/env python3
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from typing import Optional

def sanitize_html(html: str) -> str:
    # Remove malformed attribute fragments such as ' / width="400"'
    html = re.sub(r'\s/ (width|height)="[^"]+"', '', html)
    return html

def html_to_markdown(html: str) -> str:
    snippet = html.strip()
    if not snippet:
        return ''
    proc = subprocess.run(
        ['pandoc', '-f', 'html', '-t', 'gfm', '--wrap=none'],
        input=snippet.encode('utf-8'),
        capture_output=True,
        check=True,
    )
    return proc.stdout.decode('utf-8').strip()

def cell_inner_html(cell: ET.Element) -> str:
    parts = []
    if cell.text:
        parts.append(cell.text)
    for child in list(cell):
        parts.append(ET.tostring(child, encoding='unicode', method='html'))
        if child.tail:
            parts.append(child.tail)
    return ''.join(parts).strip()

def clean_heading_text(text: str) -> str:
    stripped = re.sub(r'<[^>]+>', '', text)
    stripped = stripped.replace('*', '')
    stripped = stripped.replace('_', '')
    stripped = stripped.replace('`', '')
    stripped = stripped.replace('\\', '')
    stripped = stripped.strip()
    stripped = stripped.rstrip(':：').strip()
    stripped = re.sub(r'\s*/\s*/\s*', ' / ', stripped)
    return stripped

def make_heading(text: str, level: int) -> str:
    clean = clean_heading_text(text)
    if not clean:
        return ''
    hashes = '#' * max(1, level)
    return f'{hashes} {clean}'

def first_nonempty_line(markdown: str):
    lines = markdown.splitlines()
    for idx, line in enumerate(lines):
        if line.strip():
            return idx, line
    return None, ''

def process_section_cell(cell: ET.Element, heading_level: int) -> str:
    md = html_to_markdown(cell_inner_html(cell))
    md = md.strip()
    if not md:
        return ''
    idx, heading_line = first_nonempty_line(md)
    if heading_line:
        heading = make_heading(heading_line, heading_level)
        rest = '\n'.join(md.splitlines()[idx + 1:]).strip()
        parts = [heading]
        if rest:
            parts.append(rest)
        return '\n\n'.join(parts).strip()
    return md

def process_full_span_cell(cell: ET.Element, heading_level: int) -> str:
    content = html_to_markdown(cell_inner_html(cell))
    content = content.strip()
    if not content:
        return ''
    idx, heading_line = first_nonempty_line(content)
    if heading_line and not heading_line.lstrip().startswith('!['):
        heading = make_heading(heading_line, heading_level)
        rest = '\n'.join(content.splitlines()[idx + 1:]).strip()
        parts = [heading]
        if rest:
            parts.append(rest)
        return '\n\n'.join(parts).strip()
    return content

def cell_is_empty(cell: ET.Element) -> bool:
    return cell_inner_html(cell).strip() == ''

def cell_is_heading_only(cell: ET.Element) -> Optional[str]:
    html = cell_inner_html(cell)
    if not html:
        return None
    if any(tag in html for tag in ('<ol', '<ul', '<table', '<img', '<div', '<blockquote')):
        return None
    text = clean_heading_text(html)
    if text and len(text) <= 120:
        return text
    return None

def get_rows(table: ET.Element):
    bodies = table.findall('.//tbody')
    if bodies:
        for body in bodies:
            for row in body.findall('tr'):
                yield row
    else:
        for row in table.findall('tr'):
            yield row

def convert_two_col_table(table: ET.Element) -> str:
    pre_rows = []
    post_rows = []
    left_cells = []
    right_cells = []
    seen_columns = False

    thead = table.find('thead')
    if thead is not None:
        for row in thead.findall('tr'):
            cells = row.findall('th') or row.findall('td')
            if cells:
                pre_rows.append(cells[0])

    for row in get_rows(table):
        cells = row.findall('td')
        if not cells:
            continue
        colspans = [int(cell.get('colspan', '1')) for cell in cells]
        is_column_row = len(cells) >= 2 and all(span == 1 for span in colspans[:2])
        if is_column_row:
            seen_columns = True
            left_cells.append(cells[0])
            right_cells.append(cells[-1])
            continue
        target = post_rows if seen_columns else pre_rows
        target.append(cells[0])

    sections = []
    for idx, cell in enumerate(pre_rows):
        heading_level = 1 if idx == 0 else 2
        block = process_full_span_cell(cell, heading_level)
        if block:
            sections.append(block)

    for cell in left_cells:
        block = process_section_cell(cell, 3)
        if block:
            sections.append(block)

    for cell in right_cells:
        block = process_section_cell(cell, 3)
        if block:
            sections.append(block)

    for cell in post_rows:
        block = process_full_span_cell(cell, 2)
        if block:
            sections.append(block)

    return '\n\n'.join(sections).strip() + '\n'

def convert_three_col_table(table: ET.Element) -> str:
    left_sections = []
    right_sections = []

    thead = table.find('thead')
    if thead is not None:
        header_row = thead.find('tr')
        if header_row is not None:
            headers = header_row.findall('th')
            if headers:
                left_title = headers[0].text or ''
                right_title = headers[-1].text or ''
                if left_title.strip():
                    left_sections.append(make_heading(left_title, 2))
                if right_title.strip():
                    right_sections.append(make_heading(right_title, 2))

    for row in get_rows(table):
        cells = row.findall('td')
        if not cells:
            continue
        left_cell = cells[0]
        right_cell = cells[-1]

        heading_text = cell_is_heading_only(left_cell)
        if heading_text:
            left_sections.append(make_heading(heading_text, 2))
        elif not cell_is_empty(left_cell):
            block = process_section_cell(left_cell, 3)
            if block:
                left_sections.append(block)

        heading_text = cell_is_heading_only(right_cell)
        if heading_text:
            right_sections.append(make_heading(heading_text, 2))
        elif not cell_is_empty(right_cell):
            block = process_section_cell(right_cell, 3)
            if block:
                right_sections.append(block)

    combined = []
    combined.extend(section.strip() for section in left_sections if section and section.strip())
    combined.extend(section.strip() for section in right_sections if section and section.strip())
    return '\n\n'.join(combined).strip() + '\n'

def json_to_html(json_text: str) -> str:
    proc = subprocess.run(
        ['pandoc', '-f', 'json', '-t', 'html'],
        input=json_text.encode('utf-8'),
        capture_output=True,
        check=True,
    )
    return proc.stdout.decode('utf-8')

def convert_table(json_text: str, table_type: str) -> str:
    html = sanitize_html(json_to_html(json_text))
    table = ET.fromstring(html)
    if table_type == 'keypad-three-col':
        return convert_three_col_table(table)
    return convert_two_col_table(table)

def convert_table_block(doc_obj: dict, table_block: dict, table_type: str) -> str:
    table_doc = {
        'pandoc-api-version': doc_obj.get('pandoc-api-version', [1, 23, 1]),
        'meta': doc_obj.get('meta', {}),
        'blocks': [table_block],
    }
    return convert_table(json.dumps(table_doc), table_type)

def rewrite_markdown(text: str) -> str:
    pattern = re.compile(
        r'```keypad-table\s+(?P<kind>[^\n]+)\n(?P<body>.*?)```',
        re.DOTALL | re.IGNORECASE,
    )

    def replacer(match):
        table_type = match.group('kind').strip()
        json_text = match.group('body').strip()
        # Remove potential trailing language info
        if json_text.endswith('```'):
            json_text = json_text[:-3].rstrip()
        try:
            return convert_table(json_text, table_type)
        except Exception as exc:
            raise RuntimeError(f'Failed to rewrite keypad table ({table_type}): {exc}') from exc

    replaced = pattern.sub(replacer, text)
    if replaced != text:
        return replaced

    # Fallback: sometimes the Pandoc JSON lands as a leading H1 line like
    # # { "pandoc-api-version": ..., "blocks": [ { "t": "Table", ... } ] }
    # Grab that JSON, detect the keypad type, and rewrite it.
    if replaced.lstrip().startswith('# {'):
        json_start = replaced.find('{')
        try:
            decoder = json.JSONDecoder()
            doc_obj, end_idx = decoder.raw_decode(replaced[json_start:])
            blocks = doc_obj.get('blocks') or []
            if blocks and isinstance(blocks[0], dict) and blocks[0].get('t') == 'Table':
                table = blocks[0]
                attrs = table.get('c', [[], [], []])[0]
                keyvals = attrs[2] if len(attrs) >= 3 else []
                table_type = dict(keyvals).get('data-keypad-table', 'keypad-two-col')
                remainder = replaced[json_start + end_idx :]
                table_md = convert_table_block(doc_obj, table, table_type).strip()
                remainder = remainder.lstrip()
                if table_md and remainder:
                    return f"{table_md}\n\n{remainder}"
                if table_md:
                    return table_md + "\n"
                return remainder
        except Exception:
            # If parsing fails, drop the first line to avoid leaving JSON junk.
            lines = replaced.splitlines()
            if lines and lines[0].lstrip().startswith('# {'):
                return '\n'.join(lines[1:]).lstrip()

    return replaced

def main():
    if len(sys.argv) != 2:
        print('Usage: rewrite-keypad-tables.py <index.md>', file=sys.stderr)
        sys.exit(1)
    path = sys.argv[1]
    content = open(path, 'r', encoding='utf-8').read()
    if 'data-keypad-table' not in content:
        return
    updated = rewrite_markdown(content)
    if updated != content:
        with open(path, 'w', encoding='utf-8') as fh:
            fh.write(updated)

if __name__ == '__main__':
    main()
