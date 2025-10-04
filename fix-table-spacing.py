#!/usr/bin/env python3
"""
Ensures proper spacing between lists/content and tables.
Adds blank line before tables that immediately follow:
- Numbered list items
- Note/admonition blocks
- Any other content without proper spacing
"""
import sys
import re

def fix_table_spacing(content):
    """Add blank line before tables when missing."""
    lines = content.split('\n')
    result = []
    i = 0
    
    while i < len(lines):
        current_line = lines[i]
        result.append(current_line)
        
        # Check if next line starts a table
        if i < len(lines) - 1:
            next_line = lines[i + 1]
            is_table_start = next_line.strip().startswith('|') and '|' in next_line.strip()[1:]
            
            if is_table_start:
                # Check if current line is non-empty and non-blank
                current_is_content = current_line.strip() and not current_line.strip().startswith('#')
                
                # Add blank line if missing
                if current_is_content:
                    result.append('')
        
        i += 1
    
    return '\n'.join(result)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: fix-table-spacing.py <file.md>")
        sys.exit(1)
    
    filepath = sys.argv[1]
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    fixed_content = fix_table_spacing(content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(fixed_content)
    
    print(f"Fixed table spacing in {filepath}")
