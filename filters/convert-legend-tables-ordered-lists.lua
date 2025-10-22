-- convert-legend-tables-ordered-lists.lua
-- Converts legend tables (2-column tables with ordered lists in each cell) to note admonitions
-- Example: Table with items 1-5 in left cell, items 6-9 in right cell → Note with items 1-9

local S = pandoc.utils.stringify

-- Extract all list items from ordered lists in a cell's blocks
local function extract_list_items(blocks)
    local items = {}
    for _, block in ipairs(blocks) do
        if block.t == "OrderedList" then
            for _, item_blocks in ipairs(block.content) do
                -- Each item is a list of blocks (usually Plain or Para)
                local item_text = S(pandoc.Div(item_blocks)):gsub("^%s+", ""):gsub("%s+$", "")
                if item_text ~= "" then
                    table.insert(items, item_text)
                end
            end
        end
    end
    return items
end

-- Check if blocks contain only ordered lists
local function has_only_ordered_lists(blocks)
    if #blocks == 0 then return false end
    for _, block in ipairs(blocks) do
        if block.t ~= "OrderedList" then
            return false
        end
    end
    return true
end

-- Get single row from table (either from head or body)
local function get_single_row(tbl)
    local head_rows = (tbl.head and tbl.head.rows) or {}
    local body_rows = {}
    if tbl.bodies and tbl.bodies[1] and tbl.bodies[1].body then
        body_rows = tbl.bodies[1].body
    end
    local total = #head_rows + #body_rows
    if total ~= 1 then return nil end
    return (#head_rows == 1) and head_rows[1] or body_rows[1]
end

return {
    {
        Table = function(tbl)
            -- Only act on exactly 1 row, 2 cells
            local row = get_single_row(tbl)
            if not row or not row.cells or #row.cells ~= 2 then
                return nil
            end

            local left_cell = row.cells[1]
            local right_cell = row.cells[2]

            -- Extract blocks
            local left_blocks = left_cell.contents
            local right_blocks = right_cell.contents

            -- Check if both cells contain only ordered lists
            if not (has_only_ordered_lists(left_blocks) and has_only_ordered_lists(right_blocks)) then
                return nil
            end

            -- Extract all items from both columns
            local left_items = extract_list_items(left_blocks)
            local right_items = extract_list_items(right_blocks)

            -- Merge all items
            local all_items = {}
            for _, item in ipairs(left_items) do
                table.insert(all_items, item)
            end
            for _, item in ipairs(right_items) do
                table.insert(all_items, item)
            end

            if #all_items == 0 then
                return nil
            end

            -- Build GitHub-style note alert with all items
            local lines = {}
            table.insert(lines, "> [!NOTE]")

            for i, item in ipairs(all_items) do
                table.insert(lines, "> " .. i .. ". " .. item)
                -- Add blank line between items (except last)
                if i < #all_items then
                    table.insert(lines, ">")
                end
            end

            local alert_md = table.concat(lines, "\n")
            return pandoc.RawBlock("markdown", alert_md)
        end
    }
}
