#!/usr/bin/env lua

-- Fix table structure issues from DOCX conversion
-- Problems addressed:
-- 1. H1 tags inside table cells (should be plain text)
-- 2. Empty TR rows that create layout problems
-- 3. Malformed rowspan structures
-- 4. Table headers mixed with data cells

function RawBlock(elem)
    if elem.format ~= "html" then
        return elem
    end

    local content = elem.text

    -- Fix H1 tags inside table cells - convert to strong text
    content = content:gsub('<td[^>]*><h1[^>]*><strong>([^<]+)</strong></h1>', '<td><strong>%1</strong>')
    content = content:gsub('<th[^>]*><h1[^>]*><strong>([^<]+)</strong></h1>', '<th><strong>%1</strong>')

    -- Remove empty paragraph tags in table cells that just contain the h1
    content = content:gsub('<td[^>]*><h1[^>]*><strong>([^<]+)</strong></h1>%s*<p>([^<]*)</p></td>', '<td><strong>%1</strong><p>%2</p></td>')

    -- Fix table structure: Remove empty <tr> rows
    content = content:gsub('<tr>%s*</tr>', '')

    -- Fix malformed rowspan tables by converting problematic headers to proper thead
    -- Look for tables with rowspan="2" in first row followed by empty row
    local function fix_table_headers(table_content)
        -- Check if this table has the malformed header pattern
        local has_rowspan_headers = table_content:match('<td rowspan="2"><strong>[^<]+</strong>')

        if has_rowspan_headers then
            print("Fixing malformed table with rowspan headers")

            -- Extract the header names from the first row
            local headers = {}
            for header in table_content:gmatch('<td rowspan="2"><strong>([^<]+)</strong>') do
                table.insert(headers, header)
            end

            if #headers >= 2 then
                -- Create proper table structure
                local new_table = table_content

                -- Replace the malformed tbody with proper thead and tbody
                new_table = new_table:gsub('<tbody>%s*<tr>%s*<td rowspan="2"><strong>' .. headers[1] .. '</strong>.-</tr>%s*<tr>%s*</tr>',
                    '<thead>\n<tr>\n<th><strong>' .. headers[1] .. '</strong></th>\n<th><strong>' .. headers[2] .. '</strong></th>\n</tr>\n</thead>\n<tbody>')

                return new_table
            end
        end

        return table_content
    end

    -- Apply table header fixes to each table
    content = content:gsub('<table[^>]*>.-</table>', fix_table_headers)

    return pandoc.RawBlock("html", content)
end

function Table(elem)
    -- Additional Pandoc table element processing if needed
    return elem
end