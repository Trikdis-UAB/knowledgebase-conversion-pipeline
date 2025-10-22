--[[
Flatten tables that are actually numbered lists with empty second column.

Detects tables where:
- First column contains numbered list items (starting with "1.", "2.", etc.) or regular text
- Second column is empty (no content or just whitespace)
- Converts to proper numbered list or regular paragraphs

Example input:
| Launch app. Log in. |  |
|---------------------|--|
| 1. Press „Settings". |  |
| Press „System". |  |
| Press „Users". |  |

Example output:
Launch app. Log in.

1. Press „Settings".
2. Press „System".
3. Press „Users".
]]

local function is_empty_cell(cell)
    if not cell.contents or #cell.contents == 0 then
        return true
    end

    -- Check if all blocks are empty
    for _, block in ipairs(cell.contents) do
        if block.t == "Para" or block.t == "Plain" then
            local text = pandoc.utils.stringify(block)
            -- Trim whitespace
            text = text:match("^%s*(.-)%s*$")
            if text and text ~= "" then
                return false
            end
        elseif block.t ~= "Para" and block.t ~= "Plain" then
            -- Non-paragraph content (table, image, etc)
            return false
        end
    end

    return true
end

local function starts_with_number(text)
    -- Check if text starts with "1." or "1. " (numbered list)
    return text:match("^%d+%.%s")
end

local function is_numbered_list_table(tbl)
    -- Check if table has body
    if not tbl.bodies or #tbl.bodies == 0 then
        return false
    end

    local tbody = tbl.bodies[1]
    if not tbody.body or #tbody.body == 0 then
        return false
    end

    -- Collect all rows (head + body)
    local all_rows = {}
    if tbl.head and tbl.head.rows then
        for _, row in ipairs(tbl.head.rows) do
            table.insert(all_rows, row)
        end
    end
    for _, row in ipairs(tbody.body) do
        table.insert(all_rows, row)
    end

    -- Need at least 2 rows to be worth converting
    if #all_rows < 2 then
        return false
    end

    -- Check if most rows match the pattern:
    -- - Exactly 2 cells
    -- - Second cell is empty
    -- - First cell has content
    local matching_rows = 0
    local numbered_rows = 0

    for _, row in ipairs(all_rows) do
        if #row.cells == 2 then
            local first_cell = row.cells[1]
            local second_cell = row.cells[2]

            if is_empty_cell(second_cell) and not is_empty_cell(first_cell) then
                matching_rows = matching_rows + 1

                -- Check if this row starts with a number
                local text = pandoc.utils.stringify(first_cell.contents)
                if starts_with_number(text) then
                    numbered_rows = numbered_rows + 1
                end
            end
        end
    end

    -- If 75% or more rows match the pattern, consider it a numbered list table
    local match_ratio = matching_rows / #all_rows
    return match_ratio >= 0.75 and matching_rows >= 2
end

local function flatten_numbered_list_table(tbl)
    -- Collect all rows
    local all_rows = {}
    if tbl.head and tbl.head.rows then
        for _, row in ipairs(tbl.head.rows) do
            table.insert(all_rows, row)
        end
    end

    local tbody = tbl.bodies[1]
    for _, row in ipairs(tbody.body) do
        table.insert(all_rows, row)
    end

    -- Extract content from first column
    local blocks = {}
    local list_items = {}
    local in_list = false
    local list_counter = 1

    for _, row in ipairs(all_rows) do
        if #row.cells >= 1 then
            local first_cell = row.cells[1]
            if not is_empty_cell(first_cell) then
                local text = pandoc.utils.stringify(first_cell.contents)
                text = text:match("^%s*(.-)%s*$")  -- Trim

                -- Check if this starts with a number
                local num_prefix = text:match("^(%d+)%.%s")

                if num_prefix then
                    -- This is a numbered item
                    -- Remove the number prefix
                    local content_text = text:gsub("^%d+%.%s*", "")

                    -- Start a new list if needed
                    if not in_list then
                        in_list = true
                        list_counter = tonumber(num_prefix) or 1
                    end

                    -- Create list item with original content
                    local item_blocks = {}
                    for _, block in ipairs(first_cell.contents) do
                        if block.t == "Para" or block.t == "Plain" then
                            -- Replace the text but keep formatting
                            local new_inlines = {}
                            for _, inline in ipairs(block.content) do
                                if inline.t == "Str" then
                                    -- Replace first occurrence of number prefix
                                    local new_text = pandoc.utils.stringify(inline):gsub("^%d+%.%s*", "", 1)
                                    if new_text ~= "" then
                                        table.insert(new_inlines, pandoc.Str(new_text))
                                    end
                                else
                                    table.insert(new_inlines, inline)
                                end
                            end
                            table.insert(item_blocks, pandoc.Plain(new_inlines))
                        else
                            table.insert(item_blocks, block)
                        end
                    end

                    table.insert(list_items, item_blocks)
                else
                    -- Not a numbered item
                    -- If we were in a list, close it
                    if in_list then
                        -- Create ordered list
                        local list_items_for_list = {}
                        for _, item_content in ipairs(list_items) do
                            table.insert(list_items_for_list, item_content)
                        end
                        table.insert(blocks, pandoc.OrderedList(list_items_for_list))

                        -- Reset
                        list_items = {}
                        in_list = false
                    end

                    -- Add as regular paragraph(s)
                    for _, block in ipairs(first_cell.contents) do
                        table.insert(blocks, block)
                    end
                end
            end
        end
    end

    -- Close any remaining list
    if in_list and #list_items > 0 then
        local list_items_for_list = {}
        for _, item_content in ipairs(list_items) do
            table.insert(list_items_for_list, item_content)
        end
        table.insert(blocks, pandoc.OrderedList(list_items_for_list))
    end

    return blocks
end

function Table(tbl)
    if is_numbered_list_table(tbl) then
        io.stderr:write("Flattening numbered list table with " .. (#tbl.bodies > 0 and #tbl.bodies[1].body or 0) .. " rows\n")
        return flatten_numbered_list_table(tbl)
    end

    return tbl
end

return {{Table = Table}}
