#!/usr/bin/env lua

-- Remove empty separator columns from tables
-- These are columns that are completely empty across all rows
-- Common in Word documents as visual separators but bad for web

function Table(tbl)
    -- Check if table has any rows
    if #tbl.bodies == 0 or #tbl.bodies[1].body == 0 then
        return tbl
    end

    local num_cols = #tbl.colspecs
    if num_cols == 0 then
        return tbl
    end

    -- Track which columns are empty (all cells empty or whitespace-only)
    local empty_columns = {}
    local header_only_columns = {}  -- Columns with header but all empty data cells
    for i = 1, num_cols do
        empty_columns[i] = true  -- Assume empty until proven otherwise
        header_only_columns[i] = false
    end

    -- Helper function to check if a cell is empty
    local function is_cell_empty(cell)
        if not cell then
            return true
        end

        -- In Pandoc, cell is a table with 'contents' field
        local contents = cell.contents or cell
        if not contents or #contents == 0 then
            return true
        end

        -- Check all blocks in the cell
        for _, block in ipairs(contents) do
            if block.t == "Plain" or block.t == "Para" then
                -- Check if there's any non-whitespace content
                if #block.content > 0 then
                    for _, inline in ipairs(block.content) do
                        if inline.t == "Str" and inline.text:match("%S") then
                            return false
                        elseif inline.t ~= "Space" and inline.t ~= "SoftBreak" then
                            return false
                        end
                    end
                end
            elseif block.t ~= "Null" then
                -- Any other block type means it's not empty
                return false
            end
        end

        return true
    end

    -- Check header rows
    if tbl.head and tbl.head.rows then
        for _, row in ipairs(tbl.head.rows) do
            for col_idx, cell in ipairs(row.cells) do
                if not is_cell_empty(cell) then
                    empty_columns[col_idx] = false
                    -- Mark as potential header-only column
                    header_only_columns[col_idx] = true
                end
            end
        end
    end

    -- Check body rows
    for _, body in ipairs(tbl.bodies) do
        for _, row in ipairs(body.body) do
            for col_idx, cell in ipairs(row.cells) do
                if col_idx <= num_cols and not is_cell_empty(cell) then
                    empty_columns[col_idx] = false
                    header_only_columns[col_idx] = false  -- Has data, not header-only
                end
            end
        end
    end

    -- Helper to extract text from inline elements (handles Strong, Emph, etc.)
    local function get_inline_text(inline)
        if inline.t == "Str" then
            return inline.text
        elseif inline.t == "Strong" or inline.t == "Emph" then
            -- Extract text from formatted elements
            local text = ""
            for _, inner in ipairs(inline.content) do
                text = text .. get_inline_text(inner)
            end
            return text
        end
        return ""
    end

    -- Helper to check if cell has any non-whitespace content
    local function has_non_whitespace(cell)
        if not cell then
            return false
        end
        local contents = cell.contents or cell
        if not contents or #contents == 0 then
            return false
        end
        for _, block in ipairs(contents) do
            if block.t == "Plain" or block.t == "Para" then
                for _, inline in ipairs(block.content) do
                    local text = get_inline_text(inline)
                    if text:match("%S") then  -- Has non-whitespace
                        return true
                    end
                end
            elseif block.t ~= "Null" then
                return true
            end
        end
        return false
    end

    -- Detect single-char header columns with only whitespace in data cells
    for i = 1, num_cols do
        if tbl.head and tbl.head.rows then
            local has_single_char_header = false
            local header_text = ""

            -- Check if header is single character
            for _, row in ipairs(tbl.head.rows) do
                if row.cells[i] then
                    local cell = row.cells[i]
                    local contents = cell.contents or cell
                    if contents and #contents > 0 then
                        for _, block in ipairs(contents) do
                            if block.t == "Plain" or block.t == "Para" then
                                for _, inline in ipairs(block.content) do
                                    local text = get_inline_text(inline)
                                    if #text == 1 then
                                        has_single_char_header = true
                                        header_text = text
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- If header is single char, check if all data cells are whitespace-only
            if has_single_char_header then
                local all_data_empty = true
                for _, body in ipairs(tbl.bodies) do
                    for _, row in ipairs(body.body) do
                        if row.cells[i] and has_non_whitespace(row.cells[i]) then
                            all_data_empty = false
                            break
                        end
                    end
                    if not all_data_empty then
                        break
                    end
                end

                if all_data_empty then
                    empty_columns[i] = true
                    print(string.format("Column %d has single-char header '%s' with only whitespace in data - treating as separator", i, header_text))
                end
            end
        end
    end

    -- Check foot rows
    if tbl.foot and tbl.foot.rows then
        for _, row in ipairs(tbl.foot.rows) do
            for col_idx, cell in ipairs(row.cells) do
                if not is_cell_empty(cell) then
                    empty_columns[col_idx] = false
                end
            end
        end
    end

    -- Count how many columns to remove
    local cols_to_remove = 0
    for i = 1, num_cols do
        if empty_columns[i] then
            cols_to_remove = cols_to_remove + 1
        end
    end

    -- If no empty columns, return original table
    if cols_to_remove == 0 then
        return tbl
    end

    -- If ALL columns are empty, return original (safety check)
    if cols_to_remove == num_cols then
        return tbl
    end

    print(string.format("Removing %d empty separator column(s) from table", cols_to_remove))

    -- Build new table with non-empty columns only
    local new_colspecs = {}
    for i, spec in ipairs(tbl.colspecs) do
        if not empty_columns[i] then
            table.insert(new_colspecs, spec)
        end
    end

    -- Helper to filter row cells
    local function filter_row_cells(row)
        local new_cells = {}
        for i, cell in ipairs(row.cells) do
            if i <= num_cols and not empty_columns[i] then
                table.insert(new_cells, cell)
            end
        end
        row.cells = new_cells
        return row
    end

    -- Filter header rows
    if tbl.head and tbl.head.rows then
        for i, row in ipairs(tbl.head.rows) do
            tbl.head.rows[i] = filter_row_cells(row)
        end
    end

    -- Filter body rows
    for _, body in ipairs(tbl.bodies) do
        for i, row in ipairs(body.body) do
            body.body[i] = filter_row_cells(row)
        end
    end

    -- Filter foot rows
    if tbl.foot and tbl.foot.rows then
        for i, row in ipairs(tbl.foot.rows) do
            tbl.foot.rows[i] = filter_row_cells(row)
        end
    end

    -- Update column specifications
    tbl.colspecs = new_colspecs

    return tbl
end
