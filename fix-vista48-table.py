#!/usr/bin/env python3
"""
Fix the Honeywell Vista 48 special settings table.
This table appears as 3 tables side-by-side in the PDF, but gets converted
as a single 6-column table. We need to split it into 3 separate 2-column tables.
"""

import re
import sys


def fix_vista48_table(content):
    """
    Find and fix the Honeywell Vista 48 special settings table.

    The table has pattern:
    | Section | Data | Section | Data | Section | Data |

    We want to split it into 3 separate tables:
    | Section | Data |
    """

    # Find the Vista 48 section
    vista48_marker = "SPECIAL SETTINGS FOR HONEYWELL VISTA 48 PANEL"

    if vista48_marker not in content:
        return content

    # Split content at the marker
    before = content[:content.index(vista48_marker)]
    after_marker = content[content.index(vista48_marker):]

    # Find the table - it starts after "described:" and ends before "When all required"
    table_start_marker = "set the following sections as described:\n\n"
    table_end_marker = "\n\nWhen all required settings"

    if table_start_marker not in after_marker or table_end_marker not in after_marker:
        return content

    intro = after_marker[:after_marker.index(table_start_marker) + len(table_start_marker)]
    table_section = after_marker[after_marker.index(table_start_marker) + len(table_start_marker):after_marker.index(table_end_marker)]
    outro = after_marker[after_marker.index(table_end_marker):]

    # Parse the table
    lines = table_section.strip().split('\n')

    # Extract header and separator
    header_line = None
    sep_line = None
    data_lines = []

    for line in lines:
        if '|' not in line:
            continue
        parts = [p.strip() for p in line.split('|')]
        parts = [p for p in parts if p or line.startswith('|')]

        if header_line is None:
            header_line = line
        elif sep_line is None:
            sep_line = line
        else:
            data_lines.append(line)

    # Build 3 separate tables
    table1 = []
    table2 = []
    table3 = []

    # Add headers
    table1.append("| Section | Data |")
    table1.append("|:-------:|------|")
    table2.append("| Section | Data |")
    table2.append("|:-------:|:----:|")
    table3.append("| Section | Data |")
    table3.append("|:-------:|:----:|")

    # Process data rows
    for line in data_lines:
        parts = [p.strip() for p in line.split('|')]
        # Remove empty first and last elements from pipe splitting
        if parts and parts[0] == '':
            parts = parts[1:]
        if parts and parts[-1] == '':
            parts = parts[:-1]

        if len(parts) >= 6:
            table1.append(f"| {parts[0]} | {parts[1]} |")
            table2.append(f"| {parts[2]} | {parts[3]} |")
            if parts[4]:  # Only add row if first column has content
                table3.append(f"| {parts[4]} | {parts[5]} |")

    # Rebuild content
    result = before + intro
    result += '\n'.join(table1) + '\n\n'
    result += '\n'.join(table2) + '\n\n'
    result += '\n'.join(table3) + '\n'
    result += outro

    return result


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: fix-vista48-table.py <file>")
        sys.exit(1)

    filename = sys.argv[1]

    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()

    fixed_content = fix_vista48_table(content)

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(fixed_content)

    print(f"Fixed Vista 48 table in {filename}")
