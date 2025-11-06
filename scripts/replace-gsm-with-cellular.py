#!/usr/bin/env python3
"""
replace-gsm-with-cellular.py
Replaces GSM references with Cellular in gate controller manuals
"""

import sys
import re

def replace_gsm_with_cellular(content):
    """
    Replace GSM with Cellular in text, preserving proper context.

    Replacements:
    - "GSM gate controller" → "Cellular gate controller"
    - "GSM controller" → "Cellular controller"
    - "GSM network" → "Cellular network"
    - "GSM antenna" → "Cellular antenna"
    - "GSM signal" → "Cellular signal"
    - "GSM modem" → "Cellular modem" (even in technical specs)
    - "2G GSM modem" → "2G cellular modem"

    Preserves:
    - Case variations (GSM, Gsm, gsm)
    - Technical specifications context
    """

    # Define replacement patterns (DOTALL mode for multi-line matches)
    replacements = [
        # Gate controller references (handle line breaks)
        (r'\bGSM\s+gate\s+controller\b', 'Cellular gate controller', re.DOTALL),
        (r'\bGsm\s+gate\s+controller\b', 'Cellular gate controller', re.DOTALL),
        (r'\bgsm\s+gate\s+controller\b', 'cellular gate controller', re.DOTALL),

        # Generic controller references (handle line breaks)
        (r'\bGSM\s+controller\b', 'Cellular controller', re.DOTALL),
        (r'\bGsm\s+controller\b', 'Cellular controller', re.DOTALL),
        (r'\bgsm\s+controller\b', 'cellular controller', re.DOTALL),

        # Network references (handle line breaks)
        (r'\bGSM\s+network\b', 'Cellular network', re.DOTALL),
        (r'\bGsm\s+network\b', 'Cellular network', re.DOTALL),
        (r'\bgsm\s+network\b', 'cellular network', re.DOTALL),

        # Antenna references (handle line breaks)
        (r'\bGSM\s+antenna\b', 'Cellular antenna', re.DOTALL),
        (r'\bGsm\s+antenna\b', 'Cellular antenna', re.DOTALL),
        (r'\bgsm\s+antenna\b', 'cellular antenna', re.DOTALL),

        # Signal references (handle line breaks)
        (r'\bGSM\s+signal\b', 'Cellular signal', re.DOTALL),
        (r'\bGsm\s+signal\b', 'Cellular signal', re.DOTALL),
        (r'\bgsm\s+signal\b', 'cellular signal', re.DOTALL),

        # Modem references (including technical specs, handle line breaks)
        (r'\bGSM\s+modem\b', 'Cellular modem', re.DOTALL),
        (r'\bGsm\s+modem\b', 'Cellular modem', re.DOTALL),
        (r'\bgsm\s+modem\b', 'cellular modem', re.DOTALL),

        # 2G specifications (handle line breaks)
        (r'\b2G\s+GSM\s+modem\b', '2G cellular modem', re.DOTALL),
        (r'\b2G\s+Gsm\s+modem\b', '2G cellular modem', re.DOTALL),
        (r'\b2g\s+gsm\s+modem\b', '2g cellular modem', re.DOTALL),
    ]

    # Apply all replacements
    result = content
    for item in replacements:
        if len(item) == 3:
            pattern, replacement, flags = item
            result = re.sub(pattern, replacement, result, flags=flags)
        else:
            pattern, replacement = item
            result = re.sub(pattern, replacement, result)

    return result

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 replace-gsm-with-cellular.py <file.md>")
        sys.exit(1)

    filepath = sys.argv[1]

    try:
        # Read file
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Apply replacements
        modified_content = replace_gsm_with_cellular(content)

        # Check if any changes were made
        if modified_content != content:
            # Write back
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(modified_content)
            print(f"✓ Replaced GSM with Cellular in {filepath}")
        else:
            print(f"✓ No GSM references found in {filepath}")

    except Exception as e:
        print(f"Error processing {filepath}: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
