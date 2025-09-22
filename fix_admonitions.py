#!/usr/bin/env python3
import re
import sys

def fix_admonitions(content):
    # Pattern to match malformed admonitions
    pattern = r'^(!!! (?:note|warning(?: "[^"]*")?)) (.+)$'

    lines = content.split('\n')
    result = []
    i = 0

    while i < len(lines):
        line = lines[i]
        match = re.match(pattern, line)

        if match:
            admonition_type = match.group(1)
            first_content = match.group(2)

            # Start the admonition block
            result.append(admonition_type)
            result.append(f"    {first_content}")

            # Look ahead for continuation lines starting with >
            i += 1
            while i < len(lines) and (lines[i].startswith('>') or lines[i].strip() == ''):
                if lines[i].startswith('> '):
                    # Remove > and add proper indentation
                    result.append(f"    {lines[i][2:]}")
                elif lines[i].startswith('>'):
                    # Just > with content directly
                    result.append(f"    {lines[i][1:]}")
                elif lines[i].strip() == '':
                    # Empty line
                    result.append('')
                i += 1

            # Add an empty line after the admonition
            result.append('')
            # Don't increment i as we've already processed the next lines
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