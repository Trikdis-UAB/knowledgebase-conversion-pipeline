#!/usr/bin/env lua

-- Fix malformed rowspan tables from DOCX conversion
-- Problem: First cell contains both header and first data row: <td rowspan="2"><strong>Header</strong><p>Data</p>
-- Solution: Split into proper thead and tbody structure

function Table(tbl)
    print(string.format("DEBUG: Checking table with %d columns", #tbl.colspecs))

    -- Only process tables with 2 columns
    if #tbl.colspecs ~= 2 then
        print("DEBUG: Skipping - not 2 columns")
        return tbl
    end

    -- Check if table has header rows
    if not tbl.head or not tbl.head.rows or #tbl.head.rows == 0 then
        print("DEBUG: No header rows")
        return tbl
    end

    -- Check if table has body rows
    if #tbl.bodies == 0 or #tbl.bodies[1].body == 0 then
        return tbl
    end

    local first_body_row = tbl.bodies[1].body[1]
    if #first_body_row.cells < 2 then
        print("DEBUG: First body row has < 2 cells")
        return tbl
    end

    print(string.format("DEBUG: First body row has %d cells", #first_body_row.cells))

    -- Helper to extract text from cell
    local function get_cell_text(cell)
        local contents = cell.contents or cell
        if not contents or #contents == 0 then
            return nil
        end

        for _, block in ipairs(contents) do
            if block.t == "Plain" or block.t == "Para" then
                if #block.content > 0 then
                    for _, inline in ipairs(block.content) do
                        if inline.t == "Str" then
                            return inline.text
                        elseif inline.t == "Strong" and #inline.content > 0 then
                            for _, strong_inline in ipairs(inline.content) do
                                if strong_inline.t == "Str" then
                                    return strong_inline.text
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    -- Helper to check if cell has both Strong and Para elements (malformed pattern)
    local function has_strong_and_para(cell)
        local contents = cell.contents or cell
        if not contents or #contents == 0 then
            return false
        end

        local has_strong = false
        local has_para = false

        for _, block in ipairs(contents) do
            if block.t == "Plain" or block.t == "Para" then
                for _, inline in ipairs(block.content) do
                    if inline.t == "Strong" then
                        has_strong = true
                    end
                end
            end
        end

        -- Check for multiple blocks (Strong in one, Para in another)
        if #contents > 1 then
            for _, block in ipairs(contents) do
                if block.t == "Para" then
                    has_para = true
                end
            end
        end

        return has_strong and (#contents > 1 or has_para)
    end

    -- Check first row first cell for malformed pattern
    local first_cell = first_body_row.cells[1]
    local second_cell = first_body_row.cells[2]

    local first_has_pattern = has_strong_and_para(first_cell)
    local second_has_pattern = has_strong_and_para(second_cell)
    print(string.format("DEBUG: First cell has Strong+Para: %s, Second cell: %s",
          tostring(first_has_pattern), tostring(second_has_pattern)))

    if not (first_has_pattern and second_has_pattern) then
        print("DEBUG: Not both cells have malformed pattern")
        return tbl
    end

    print("Fixing malformed rowspan table with headers in first data row")

    -- Extract header text from Strong elements in first row
    local function extract_header_and_data(cell)
        local contents = cell.contents or cell
        local header_text = nil
        local data_blocks = {}

        for _, block in ipairs(contents) do
            if block.t == "Plain" or block.t == "Para" then
                local has_strong_in_block = false
                for _, inline in ipairs(block.content) do
                    if inline.t == "Strong" then
                        has_strong_in_block = true
                        -- Extract header text
                        for _, strong_inline in ipairs(inline.content) do
                            if strong_inline.t == "Str" then
                                header_text = strong_inline.text
                                break
                            end
                        end
                    end
                end
                -- If block doesn't have Strong, it's data
                if not has_strong_in_block and #block.content > 0 then
                    table.insert(data_blocks, block)
                end
            end
        end

        return header_text, data_blocks
    end

    -- Extract headers and data from first row
    local header1, data1 = extract_header_and_data(first_cell)
    local header2, data2 = extract_header_and_data(second_cell)

    if not (header1 and header2) then
        return tbl
    end

    -- Create new header row
    local header_row = pandoc.Row({
        pandoc.Cell(pandoc.Blocks({pandoc.Para({pandoc.Strong({pandoc.Str(header1)})})})),
        pandoc.Cell(pandoc.Blocks({pandoc.Para({pandoc.Strong({pandoc.Str(header2)})})}))
    })

    -- Create new first data row with extracted data
    local data_row = pandoc.Row({
        pandoc.Cell(pandoc.Blocks(data1)),
        pandoc.Cell(pandoc.Blocks(data2))
    })

    -- Update table structure
    tbl.head = pandoc.TableHead({header_row})

    -- Replace first body row with extracted data row
    tbl.bodies[1].body[1] = data_row

    return tbl
end
