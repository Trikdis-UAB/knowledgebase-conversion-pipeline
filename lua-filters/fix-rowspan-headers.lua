--[[
Fix malformed rowspan table headers in Pandoc AST.

When DOCX has a table with merged header cells, Pandoc creates:
- Cell with rowspan=2 containing BOTH header text and first data row
- This creates malformed HTML structure

This filter detects and fixes by:
1. Finding cells with rowspan > 1 that contain multiple paragraphs
2. Splitting header from data
3. Creating proper header row and data rows
]]

function Table(tbl)
    -- Only process tables with bodies
    if not tbl.bodies or #tbl.bodies == 0 then
        return tbl
    end

    local tbody = tbl.bodies[1]
    if not tbody.body or #tbody.body == 0 then
        return tbl
    end

    -- Check first row for cells with rowspan > 1
    local first_row = tbody.body[1]
    local needs_fix = false

    for _, cell in ipairs(first_row.cells) do
        -- Check if cell has rowspan > 1 and contains multiple blocks
        if cell.row_span and cell.row_span > 1 and #cell.contents > 1 then
            needs_fix = true
            break
        end
    end

    if not needs_fix then
        return tbl
    end

    -- Create new header row from first blocks of rowspan cells
    local header_cells = {}
    local data_cells = {}

    for i, cell in ipairs(first_row.cells) do
        if cell.row_span and cell.row_span > 1 and #cell.contents > 1 then
            -- Split: first block to header, rest to data
            local header_content = {cell.contents[1]}
            local data_content = {}
            for j = 2, #cell.contents do
                table.insert(data_content, cell.contents[j])
            end

            -- Create header cell (no rowspan)
            table.insert(header_cells, {
                attr = cell.attr,
                alignment = cell.alignment,
                contents = header_content,
                col_span = cell.col_span or 1,
                row_span = 1
            })

            -- Create data cell
            table.insert(data_cells, {
                attr = cell.attr,
                alignment = cell.alignment,
                contents = data_content,
                col_span = cell.col_span or 1,
                row_span = 1
            })
        else
            -- Normal cell - copy to header
            table.insert(header_cells, cell)
        end
    end

    -- If we extracted headers, create proper header structure
    if #header_cells > 0 and #data_cells > 0 then
        -- Move header cells to table head
        tbl.head = {
            attr = pandoc.Attr(),
            rows = {{
                attr = pandoc.Attr(),
                cells = header_cells
            }}
        }

        -- Replace first body row with data cells
        tbody.body[1] = {
            attr = pandoc.Attr(),
            cells = data_cells
        }
    end

    return tbl
end

return {{Table = Table}}
