--[[
Flatten multi-row instruction tables (text + image in each row).

Detects tables where:
- Each row has 2 cells
- One cell contains text/instructions
- Other cell contains an image
- Converts to sequential numbered list with images after each step

Example input:
<table>
  <tr><td>1. Do this</td><td><img></td></tr>
  <tr><td>2. Do that</td><td><img></td></tr>
</table>

Example output:
1. Do this

   <img>

2. Do that

   <img>
]]

local function has_image(blocks)
    for _, block in ipairs(blocks) do
        if block.t == "Para" or block.t == "Plain" then
            for _, inline in ipairs(block.content or {}) do
                if inline.t == "Image" then
                    return true
                end
            end
        end
    end
    return false
end

local function extract_images(blocks)
    local images = {}
    for _, block in ipairs(blocks) do
        if block.t == "Para" or block.t == "Plain" then
            for _, inline in ipairs(block.content or {}) do
                if inline.t == "Image" then
                    table.insert(images, inline)
                end
            end
        end
    end
    return images
end

local function is_instruction_table(tbl)
    -- Check if table has rows in body
    if not tbl.bodies or #tbl.bodies == 0 then
        return false
    end

    local tbody = tbl.bodies[1]
    if not tbody.body or #tbody.body == 0 then
        return false
    end

    -- Check head rows too
    local all_rows = {}
    if tbl.head and tbl.head.rows then
        for _, row in ipairs(tbl.head.rows) do
            table.insert(all_rows, row)
        end
    end
    for _, row in ipairs(tbody.body) do
        table.insert(all_rows, row)
    end

    -- Need at least 2 rows to be worth flattening
    if #all_rows < 2 then
        return false
    end

    -- Check if each row has exactly 2 cells with text + image pattern
    for _, row in ipairs(all_rows) do
        if not row.cells or #row.cells ~= 2 then
            return false
        end

        local cell1 = row.cells[1].contents
        local cell2 = row.cells[2].contents

        local has_img1 = has_image(cell1)
        local has_img2 = has_image(cell2)

        -- One cell should have image, other should have text
        if not ((has_img1 and not has_img2) or (has_img2 and not has_img1)) then
            return false
        end
    end

    return true
end

function Table(tbl)
    if not is_instruction_table(tbl) then
        return nil
    end

    -- Collect all rows
    local all_rows = {}
    if tbl.head and tbl.head.rows then
        for _, row in ipairs(tbl.head.rows) do
            table.insert(all_rows, row)
        end
    end
    if tbl.bodies and tbl.bodies[1] and tbl.bodies[1].body then
        for _, row in ipairs(tbl.bodies[1].body) do
            table.insert(all_rows, row)
        end
    end

    -- Convert each row to text + image
    local output = {}

    for _, row in ipairs(all_rows) do
        local cell1 = row.cells[1].contents
        local cell2 = row.cells[2].contents

        local text_cell, image_cell
        if has_image(cell1) then
            text_cell = cell2
            image_cell = cell1
        else
            text_cell = cell1
            image_cell = cell2
        end

        -- Add text content
        for _, block in ipairs(text_cell) do
            table.insert(output, block)
        end

        -- Add blank line before image
        table.insert(output, pandoc.Para({}))

        -- Extract and add images
        local images = extract_images(image_cell)
        for _, img in ipairs(images) do
            table.insert(output, pandoc.Para({img}))
        end
    end

    return output
end

return {{Table = Table}}
