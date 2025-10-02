#!/usr/bin/env lua

-- Unwrap BlockQuote elements inside table cells
-- Pandoc sometimes wraps table cell content in BlockQuote which causes
-- it to fall back to HTML tables instead of Markdown pipe tables

function Cell(cell)
    -- Get cell contents
    local contents = cell.contents or {}

    -- Process each block in the cell
    local new_contents = {}
    for _, block in ipairs(contents) do
        if block.t == "BlockQuote" then
            -- Unwrap the blockquote - add its contents directly
            for _, inner_block in ipairs(block.content) do
                table.insert(new_contents, inner_block)
            end
        else
            -- Keep non-blockquote blocks as-is
            table.insert(new_contents, block)
        end
    end

    -- Update cell contents
    cell.contents = new_contents
    return cell
end
