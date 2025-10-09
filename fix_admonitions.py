#!/usr/bin/env python3
import re
import sys

def fix_admonitions(content):
    # Pattern to match admonitions with content on same line
    pattern_same_line = r'^(!!! (?:note|warning|tip|caution|important)(?: "[^"]*")?)\s+(.+)$'
    # Pattern to match admonitions without content on same line
    pattern_admonition = r'^!!! (?:note|warning|tip|caution|important)(?: "[^"]*")?$'

    lines = content.split('\n')
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Check for admonition with content on same line
        match_same = re.match(pattern_same_line, line)
        # Check for admonition without content on same line
        match_admon = re.match(pattern_admonition, line)

        if match_same:
            # Content on same line - process it
            admonition_type = match_same.group(1)
            first_content = match_same.group(2)

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

        elif match_admon:
            # Content on next line - process it
            result.append(line)  # Add the !!! note line

            # Look ahead for content lines starting with >
            i += 1
            while i < len(lines) and (lines[i].startswith('>') or lines[i].strip() == ''):
                if lines[i].startswith('> '):
                    # Remove > and add proper indentation
                    result.append(f"    {lines[i][2:]}")
                elif lines[i].startswith('>'):
                    # Just > with content directly (or empty >)
                    if lines[i] == '>':
                        result.append('')
                    else:
                        result.append(f"    {lines[i][1:]}")
                elif lines[i].strip() == '':
                    # Empty line within admonition
                    result.append('')
                i += 1

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