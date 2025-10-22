--[[
Extract images from table cells and place them after the table.

This filter solves the problem where images embedded in table cells get lost
when table-flattening filters run. It extracts all images from tables and
preserves them by placing them immediately after the table.

Problem scenario:
- DOCX has instruction tables where each row contains text + image in cells
- Table flattening filters (flatten-instruction-tables.lua, etc.) remove the table
  but lose the images in the process
- Result: Missing images in final output (e.g., Gator manual images 21-26)

Solution:
- Run THIS filter BEFORE any table-flattening filters
- Extract all images from table cells
- Place them after the table with proper spacing
- Table-flattening filters can then safely remove tables without losing images

Usage in convert-single.sh:
  --lua-filter="extract-table-images.lua" \    # THIS FILTER FIRST
  --lua-filter="flatten-instruction-tables.lua" \
  --lua-filter="flatten-numbered-list-tables.lua" \
  ...

Example:
  Before:
    Table with cells containing:
    | Step 1: Do something | [image1.png] |
    | Step 2: Do another   | [image2.png] |

  After this filter:
    Table with cells containing:
    | Step 1: Do something |   |
    | Step 2: Do another   |   |

    [image1.png]

    [image2.png]

  After flatten-instruction-tables.lua:
    1. Step 1: Do something

    [image1.png]

    2. Step 2: Do another

    [image2.png]
]]

-- Collect images from a single table cell
local function extract_images_from_cell(cell)
    local images = {}

    if not cell.contents then
        return images
    end

    -- Walk through all blocks in the cell and collect images
    for i, block in ipairs(cell.contents) do
        pandoc.walk_block(block, {
            Image = function(img)
                table.insert(images, img)
            end
        })
    end

    -- Remove images from cell contents
    for i = #cell.contents, 1, -1 do
        cell.contents[i] = pandoc.walk_block(cell.contents[i], {
            Image = function(img)
                return {}  -- Remove the image, return empty list
            end
        })
    end

    return images
end

-- Collect images from all cells in a table
local function extract_images_from_table(tbl)
    local all_images = {}

    -- Extract from header
    if tbl.head and tbl.head.rows then
        for _, row in ipairs(tbl.head.rows) do
            if row.cells then
                for _, cell in ipairs(row.cells) do
                    local images = extract_images_from_cell(cell)
                    for _, img in ipairs(images) do
                        table.insert(all_images, img)
                    end
                end
            end
        end
    end

    -- Extract from body
    if tbl.bodies then
        for _, tbody in ipairs(tbl.bodies) do
            if tbody.body then
                for _, row in ipairs(tbody.body) do
                    if row.cells then
                        for _, cell in ipairs(row.cells) do
                            local images = extract_images_from_cell(cell)
                            for _, img in ipairs(images) do
                                table.insert(all_images, img)
                            end
                        end
                    end
                end
            end
        end
    end

    -- Extract from footer
    if tbl.foot and tbl.foot.rows then
        for _, row in ipairs(tbl.foot.rows) do
            if row.cells then
                for _, cell in ipairs(row.cells) do
                    local images = extract_images_from_cell(cell)
                    for _, img in ipairs(images) do
                        table.insert(all_images, img)
                    end
                end
            end
        end
    end

    return all_images
end

-- Process each table
function Table(tbl)
    -- Extract all images from the table
    local images = extract_images_from_table(tbl)

    -- If no images found, return table as-is
    if #images == 0 then
        return tbl
    end

    -- Create a list of blocks to return:
    -- 1. The table (now without images in cells)
    -- 2. Each extracted image as a paragraph with blank lines
    local blocks = {tbl}

    io.stderr:write(string.format("Extracted %d image(s) from table\n", #images))

    for _, img in ipairs(images) do
        -- Add blank line before image
        table.insert(blocks, pandoc.Para({}))

        -- Add image as paragraph
        table.insert(blocks, pandoc.Para({img}))

        -- Add blank line after image
        table.insert(blocks, pandoc.Para({}))
    end

    return blocks
end

return {{Table = Table}}
