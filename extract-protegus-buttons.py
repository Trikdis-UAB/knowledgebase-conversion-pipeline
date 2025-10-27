#!/usr/bin/env python3
"""
extract-protegus-buttons.py
Extracts app store button images by detecting their position in document structure.
Looks for images between "Download...Protegus" and "Log in/Launch" instructions.
"""

import sys
import subprocess
import json
import os
import shutil

def get_pandoc_ast(docx_path):
    """Get Pandoc AST in JSON format."""
    result = subprocess.run(
        ['pandoc', docx_path, '-t', 'json'],
        capture_output=True,
        text=True
    )
    return json.loads(result.stdout)

def find_button_images(ast):
    """Find image references between Download and Log in instructions."""
    blocks = ast['blocks']
    button_images = []
    in_download_section = False

    for i, block in enumerate(blocks):
        # Convert block to text for pattern matching
        block_text = get_block_text(block)

        # Start looking after "Download" instruction
        if 'download' in block_text.lower() and 'protegus' in block_text.lower():
            in_download_section = True
            continue

        # Stop looking after "Log in" or "Launch" instruction
        if in_download_section and ('log in' in block_text.lower() or 'launch the protegus' in block_text.lower()):
            break

        # Collect images in between
        if in_download_section:
            images = extract_images_from_block(block)
            button_images.extend(images)

    return button_images

def get_block_text(block):
    """Extract text content from a block."""
    if block['t'] == 'Para':
        return get_inline_text(block['c'])
    elif block['t'] == 'Plain':
        return get_inline_text(block['c'])
    elif block['t'] == 'Header':
        return get_inline_text(block['c'][2])
    return ''

def get_inline_text(inlines):
    """Extract text from inline elements."""
    text = ''
    for inline in inlines:
        if isinstance(inline, dict):
            if inline['t'] == 'Str':
                text += inline['c']
            elif inline['t'] == 'Space':
                text += ' '
            elif inline['t'] == 'Link':
                text += get_inline_text(inline['c'][1])
    return text

def extract_images_from_block(block):
    """Extract image sources from a block, including nested structures like tables."""
    images = []

    # Handle Para/Plain blocks (standalone images)
    if block['t'] == 'Para' or block['t'] == 'Plain':
        for inline in block.get('c', []):
            if isinstance(inline, dict) and inline['t'] == 'Image':
                src = inline['c'][2][0]
                if src:
                    images.append(os.path.basename(src))

    # Handle Table blocks - recurse into cells to find images
    elif block['t'] == 'Table':
        # Table structure: [attr, caption, colspecs, head, bodies, foot]
        table_content = block.get('c', [])
        if len(table_content) >= 5:
            bodies = table_content[4]  # Table bodies
            for body in bodies:
                # Body: [attr, row_head_columns, head_rows, body_rows]
                if len(body) >= 4:
                    body_rows = body[3]
                    for row in body_rows:
                        # Row: [attr, cells]
                        if len(row) >= 2:
                            cells = row[1]
                            for cell in cells:
                                # Cell: [attr, alignment, rowspan, colspan, [blocks]]
                                if len(cell) >= 5:
                                    cell_blocks = cell[4]
                                    for cell_block in cell_blocks:
                                        # Recursively extract from cell blocks
                                        images.extend(extract_images_from_block(cell_block))

    return images

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 extract-protegus-buttons.py <docx-file> <output-dir>")
        sys.exit(1)

    docx_path = sys.argv[1]
    output_dir = sys.argv[2]

    # Get AST and find button images
    ast = get_pandoc_ast(docx_path)
    button_images = find_button_images(ast)

    if not button_images:
        return  # Silent if no buttons found

    # Extract DOCX to get media files
    import tempfile
    import zipfile

    with tempfile.TemporaryDirectory() as temp_dir:
        # Unzip DOCX
        with zipfile.ZipFile(docx_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)

        media_dir = os.path.join(temp_dir, 'word', 'media')
        if not os.path.exists(media_dir):
            return

        # Copy found button images
        for img_name in button_images:
            src_path = os.path.join(media_dir, img_name)
            if os.path.exists(src_path):
                dst_path = os.path.join(output_dir, img_name)
                shutil.copy2(src_path, dst_path)
                print(f"  Found Protegus button (by position): {img_name}")

if __name__ == "__main__":
    main()

