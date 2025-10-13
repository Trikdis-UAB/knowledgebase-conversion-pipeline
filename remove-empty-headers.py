#!/usr/bin/env python3
"""
Remove empty markdown headers (e.g., "#### " with only whitespace after)
"""

import sys
import re

def remove_empty_headers(content):
    """Remove lines that are headers with only whitespace"""
    # Match any markdown header (####, ###, ##, #) followed only by whitespace
    pattern = r'^#{1,6}\s*$'
    lines = content.split('\n')
    filtered_lines = [line for line in lines if not re.match(pattern, line)]
    return '\n'.join(filtered_lines)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: remove-empty-headers.py <file.md>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    cleaned = remove_empty_headers(content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(cleaned)
    
    print(f"✓ Removed empty headers from {file_path}")
