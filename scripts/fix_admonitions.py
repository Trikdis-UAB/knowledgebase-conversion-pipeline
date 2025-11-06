#!/usr/bin/env python3
import re
import sys

def fix_admonitions(content):
    # Pattern to match admonitions with BOTH title AND content on same line (e.g., !!! note "Title" Some content)
    pattern_titled_with_content = r'^(!!! (?:note|warning|tip|caution|important) "[^"]*")\s+(.+)$'
    # Pattern to match admonitions without title but WITH content (e.g., !!! note Some content)
    # Uses negative lookahead to exclude lines with titles
    pattern_no_title_with_content = r'^(!!! (?:note|warning|tip|caution|important))(?! ")\s+(.+)$'
    # Pattern to match admonitions WITH inline title but NO content (e.g., !!! warning "Important")
    pattern_only_title = r'^(!!! (?:note|warning|tip|caution|important) "[^"]*")\s*$'
    # Pattern to match admonitions without title or content (e.g., !!! warning)
    pattern_empty = r'^!!! (?:note|warning|tip|caution|important)\s*$'

    lines = content.split('\n')
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Check all patterns (in priority order)
        match_titled_with_content = re.match(pattern_titled_with_content, line)
        match_only_title = re.match(pattern_only_title, line)
        match_no_title_with_content = re.match(pattern_no_title_with_content, line)
        match_empty = re.match(pattern_empty, line)

        if match_titled_with_content:
            # Titled admonition with content on same line
            admonition_type = match_titled_with_content.group(1)
            first_content = match_titled_with_content.group(2)

            result.append(admonition_type)
            result.append(f"    {first_content}")

            # Look ahead for continuation lines starting with >
            i += 1
            while i < len(lines) and (lines[i].startswith('>') or lines[i].strip() == ''):
                if lines[i].startswith('> '):
                    result.append(f"    {lines[i][2:]}")
                elif lines[i].startswith('>'):
                    result.append(f"    {lines[i][1:]}")
                elif lines[i].strip() == '':
                    result.append('')
                i += 1

            result.append('')
            continue

        elif match_no_title_with_content:
            # No-title admonition with content on same line
            admonition_type = match_no_title_with_content.group(1)
            first_content = match_no_title_with_content.group(2)

            result.append(admonition_type)
            result.append(f"    {first_content}")

            # Look ahead for continuation lines starting with >
            i += 1
            while i < len(lines) and (lines[i].startswith('>') or lines[i].strip() == ''):
                if lines[i].startswith('> '):
                    result.append(f"    {lines[i][2:]}")
                elif lines[i].startswith('>'):
                    result.append(f"    {lines[i][1:]}")
                elif lines[i].strip() == '':
                    result.append('')
                i += 1

            result.append('')
            continue

        elif match_only_title:
            # Admonition with inline title - just remove blockquote markers from content
            admonition_line = line  # e.g., "!!! warning \"Important\""

            result.append(admonition_line)

            # Process content lines that follow (remove blockquote markers)
            i += 1
            while i < len(lines) and (lines[i].startswith('>') or lines[i].startswith('    >') or lines[i].strip() == ''):
                line_content = lines[i]

                # Remove all combinations of blockquote markers
                if line_content.startswith('    > '):
                    result.append(f"    {line_content[6:]}")  # Remove '    > '
                elif line_content.startswith('    >'):
                    if line_content == '    >':
                        result.append('')
                    else:
                        result.append(f"    {line_content[5:]}")  # Remove '    >'
                elif line_content.startswith('> > '):
                    result.append(f"    {line_content[4:]}")  # Remove '> > '
                elif line_content.startswith('> >'):
                    if line_content == '> >':
                        result.append('')
                    else:
                        result.append(f"    {line_content[3:]}")  # Remove '> >'
                elif line_content.startswith('> '):
                    result.append(f"    {line_content[2:]}")  # Remove '> '
                elif line_content.startswith('>'):
                    if line_content == '>':
                        result.append('')
                    else:
                        result.append(f"    {line_content[1:]}")  # Remove '>'
                elif line_content.strip() == '':
                    result.append('')
                else:
                    break  # Stop at first line without blockquote marker
                i += 1

            result.append('')
            continue

        elif match_empty:
            # Content on next line - process it
            admonition_line = line  # Store original !!! note line

            # Look ahead for content lines
            i += 1
            content_lines = []

            # REMOVED: Don't check for indented quoted title here
            # If there was a title, it should have matched pattern_only_title instead

            # Now collect content lines (may have blockquote markers)
            while i < len(lines) and (lines[i].startswith('>') or lines[i].startswith('    >') or lines[i].strip() == ''):
                line_content = lines[i]

                # Remove blockquote marker and indentation
                if line_content.startswith('    > '):
                    content_lines.append(line_content[6:])  # Remove '    > '
                elif line_content.startswith('    >'):
                    if line_content == '    >':
                        content_lines.append('')
                    else:
                        content_lines.append(line_content[5:])  # Remove '    >'
                elif line_content.startswith('> '):
                    content_lines.append(line_content[2:])  # Remove '> '
                elif line_content.startswith('>'):
                    if line_content == '>':
                        content_lines.append('')
                    else:
                        content_lines.append(line_content[1:])  # Remove '>'
                elif line_content.strip() == '':
                    content_lines.append('')
                else:
                    # Content line without blockquote marker
                    content_lines.append(line_content.lstrip())
                i += 1

            # Output the admonition
            result.append(admonition_line)
            for content_line in content_lines:
                result.append(f"    {content_line}")

            # Add an empty line after the admonition
            result.append('')
            continue
        else:
            result.append(line)

        i += 1

    return '\n'.join(result)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: fix_admonitions.py <file>")
        sys.exit(1)

    filename = sys.argv[1]

    with open(filename, 'r') as f:
        content = f.read()

    fixed_content = fix_admonitions(content)

    with open(filename, 'w') as f:
        f.write(fixed_content)

    print(f"Fixed admonitions in {filename}")