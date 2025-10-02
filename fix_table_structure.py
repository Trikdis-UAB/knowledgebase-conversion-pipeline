#!/usr/bin/env python3
"""
Fix table structure issues from DOCX to Markdown conversion.

Problems addressed:
1. H1 tags inside table cells (should be plain text or th)
2. Empty TR rows that create layout problems
3. Malformed rowspan structures
4. Convert data cells with headers to proper table headers
"""

import re
import sys
from typing import List, Tuple

def fix_table_headers(content: str) -> str:
    """Convert malformed table headers from td with h1 to proper th elements."""

    # Pattern: <td rowspan="2"><h1><strong>Header</strong></h1>
    pattern = r'<td(\s+[^>]*)?><h1[^>]*><strong>([^<]+)</strong></h1>'

    def replace_header(match):
        attributes = match.group(1) or ''
        header_text = match.group(2)
        # Convert to proper table header
        return f'<th{attributes}><strong>{header_text}</strong></th>'

    return re.sub(pattern, replace_header, content)

def fix_empty_rows(content: str) -> str:
    """Remove empty table rows that cause layout issues."""

    # Remove completely empty tr tags
    content = re.sub(r'<tr>\s*</tr>', '', content)

    # Remove tr tags that only contain empty td tags
    content = re.sub(r'<tr>\s*<td[^>]*>\s*</td>\s*</tr>', '', content)

    return content

def fix_malformed_rowspan_tables(content: str) -> str:
    """Fix tables with problematic rowspan structure."""

    def fix_single_table(table_match):
        table_content = table_match.group(0)

        # Check for the specific malformed pattern we've seen:
        # <th rowspan="2">Header</th>\n<p>content</p>\n</td>
        malformed_pattern = r'<th rowspan="2"><strong>([^<]+)</strong></th>\s*<p>([^<]*)</p>\s*</td>'

        if re.search(malformed_pattern, table_content):
            print("Fixing malformed table with rowspan headers and mismatched tags")

            # Extract the headers and first row content
            headers = []
            first_row_content = []

            for match in re.finditer(malformed_pattern, table_content):
                headers.append(match.group(1))
                first_row_content.append(match.group(2))

            if len(headers) >= 2:
                # Get table structure parts
                table_start = re.search(r'<table[^>]*>.*?<tbody>', table_content, re.DOTALL)
                if table_start:
                    table_prefix = table_start.group(0)

                    # Create proper table structure
                    new_content = table_prefix + '\n'

                    # Add header row
                    new_content += '<tr>\n'
                    for header in headers:
                        new_content += f'<th><strong>{header}</strong></th>\n'
                    new_content += '</tr>\n'

                    # Add first data row
                    new_content += '<tr>\n'
                    for content in first_row_content:
                        new_content += f'<td><p>{content}</p></td>\n'
                    new_content += '</tr>\n'

                    # Remove the malformed first row and empty row
                    remaining_content = table_content
                    # Remove the malformed row
                    remaining_content = re.sub(r'<tr>\s*' + malformed_pattern + r'\s*' + malformed_pattern + r'\s*</tr>', '', remaining_content, flags=re.DOTALL)
                    # Remove empty rows
                    remaining_content = re.sub(r'<tr>\s*</tr>', '', remaining_content)

                    # Get the rest of the table after removing malformed parts
                    tbody_pattern = r'<tbody>.*?</tbody>'
                    tbody_match = re.search(tbody_pattern, remaining_content, re.DOTALL)
                    if tbody_match:
                        tbody_content = tbody_match.group(0)
                        # Extract just the rows, excluding tbody tags
                        rows_pattern = r'<tbody>\s*(.*?)\s*</tbody>'
                        rows_match = re.search(rows_pattern, tbody_content, re.DOTALL)
                        if rows_match:
                            remaining_rows = rows_match.group(1).strip()
                            if remaining_rows:
                                new_content += remaining_rows + '\n'

                    new_content += '</tbody>\n</table>'
                    return new_content

        return table_content

    # Apply fix to each table
    return re.sub(r'<table[^>]*>.*?</table>', fix_single_table, content, flags=re.DOTALL)

def fix_specifications_table(content: str) -> str:
    """Fix the malformed Specifications table structure.

    Detects tables with rowspan=2 headers that contain both header text and data,
    and restructures them into proper header row + data rows.
    """

    # Pattern: <td rowspan="2"><strong>Header</strong>\n\n<p>Data</p></td>
    # This appears in GET manual's Specifications table
    # Use DOTALL to match across newlines
    pattern = r'<tbody>\s*<tr>\s*<td rowspan="2"><strong>([^<]+)</strong>\s+<p>([^<]*)</p>\s*</td>\s*<td rowspan="2">([^<]+)</td>\s*</tr>'

    def fix_single_table(match):
        # Extract the parts
        header1 = match.group(1)  # "Parameter"
        data1 = match.group(2)     # "Network connectivity"
        header_and_data2 = match.group(3)  # "DescriptionLTE / Ethernet"

        # Split the combined header+data (e.g., "DescriptionLTE / Ethernet")
        # Look for pattern like "Description" followed by data
        header2_match = re.match(r'^(Description|Parameter)\s*(.*)$', header_and_data2)
        if header2_match:
            header2 = header2_match.group(1)
            data2 = header2_match.group(2).strip()
        else:
            # Fallback
            header2 = "Description"
            data2 = header_and_data2

        # Build proper table structure with thead and tbody
        result = '<thead>\n<tr>\n'
        result += f'<th><strong>{header1}</strong></th>\n'
        result += f'<th><strong>{header2}</strong></th>\n'
        result += '</tr>\n</thead>\n<tbody>\n<tr>\n'
        result += f'<td><p>{data1}</p></td>\n'
        result += f'<td>{data2}</td>\n'
        result += '</tr>'

        return result

    return re.sub(pattern, fix_single_table, content, flags=re.DOTALL)

def clean_table_content(content: str) -> str:
    """Clean up table cell content."""

    # Remove h1 tags from table cells with <strong> wrapper
    content = re.sub(r'<(td|th)([^>]*)><h1[^>]*><strong>([^<]+)</strong></h1>(.*?)</\1>',
                     r'<\1\2><strong>\3</strong>\4</\1>', content, flags=re.DOTALL)

    # Remove h1 tags from table cells WITHOUT <strong> wrapper (GET manual case)
    content = re.sub(r'<(td|th)([^>]*)><h1[^>]*>([^<]+)</h1>',
                     r'<\1\2><strong>\3</strong>', content, flags=re.DOTALL)

    # Clean up corrupted header separators like "Description :=============="
    content = re.sub(r'(Description|Parameter)\s*:=+\s*', r'\1', content)

    # Fix malformed rowspan table headers - convert td with h1 to th
    content = re.sub(r'<td(\s+rowspan="[^"]+")><h1[^>]*>([^<]+)</h1>',
                     r'<th\1><strong>\2</strong></th>', content)

    # Clean up empty paragraphs in table cells
    content = re.sub(r'<(td|th)([^>]*)><strong>([^<]+)</strong>\s*<p>\s*</p>',
                     r'<\1\2><strong>\3</strong>', content)

    return content

def fix_table_structure(content: str) -> str:
    """Apply all table structure fixes."""

    print("Fixing table structure issues...")

    # Step 1: Fix Specifications table structure (GET manual)
    content = fix_specifications_table(content)

    # Step 2: Fix table headers
    content = fix_table_headers(content)

    # Step 3: Remove empty rows
    content = fix_empty_rows(content)

    # Step 4: Fix malformed rowspan tables
    content = fix_malformed_rowspan_tables(content)

    # Step 5: Clean table content
    content = clean_table_content(content)

    print("Table structure fixes completed")
    return content

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: fix_table_structure.py <file>")
        sys.exit(1)

    filename = sys.argv[1]

    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()

    fixed_content = fix_table_structure(content)

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(fixed_content)

    print(f"Fixed table structure in {filename}")