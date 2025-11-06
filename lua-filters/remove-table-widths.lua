-- remove-table-widths.lua
-- Simplifies tables for markdown pipe table output
-- 1. Removes column width specifications (forces auto-width)
-- 2. Merges multi-paragraph cells into single paragraphs with line breaks
-- Reasoning: DOCX tables have explicit column widths and multi-para cells
-- Both trigger HTML output; we want human-readable markdown tables

function Table(tbl)
    -- Remove table-level attributes (width, style, etc.)
    tbl.attr = pandoc.Attr("", {}, {})  -- Empty attributes

    -- Helper function to merge multi-paragraph cells into single line
    -- Replaces <br> with " / " separator for pipe table compatibility
    local function simplify_cell(cell)
        if not cell or not cell.contents then
            return cell
        end

        -- If cell has only one block, check for RawInline br tags
        if #cell.contents == 1 then
            local block = cell.contents[1]
            if block.t == "Para" or block.t == "Plain" then
                -- Replace <br> HTML tags with " / " separator
                local new_inlines = {}
                for _, inline in ipairs(block.content) do
                    if inline.t == "RawInline" and inline.format == "html" and inline.text:match("^<br") then
                        -- Replace <br> with text separator
                        table.insert(new_inlines, pandoc.Str(" / "))
                    else
                        table.insert(new_inlines, inline)
                    end
                end
                cell.contents = {pandoc.Plain(new_inlines)}
            end
            return cell
        end

        -- Merge multiple Para/Plain blocks into one with " / " separator
        local merged_inlines = {}
        for i, block in ipairs(cell.contents) do
            if block.t == "Para" or block.t == "Plain" then
                -- Add content from this block
                for _, inline in ipairs(block.content) do
                    table.insert(merged_inlines, inline)
                end
                -- Add " / " separator between paragraphs
                if i < #cell.contents then
                    table.insert(merged_inlines, pandoc.Str(" / "))
                end
            else
                -- For other block types (lists, nested tables), keep as is
                -- These will force HTML table output anyway
                return cell
            end
        end

        -- Replace cell contents with single merged paragraph
        cell.contents = {pandoc.Plain(merged_inlines)}
        return cell
    end

    -- Simplify all cells in header
    if tbl.head and tbl.head.rows then
        for _, row in ipairs(tbl.head.rows) do
            for i, cell in ipairs(row.cells) do
                row.cells[i] = simplify_cell(cell)
            end
        end
    end

    -- Simplify all cells in body
    for _, body in ipairs(tbl.bodies) do
        for _, row in ipairs(body.body) do
            for i, cell in ipairs(row.cells) do
                row.cells[i] = simplify_cell(cell)
            end
        end
    end

    -- Simplify all cells in footer
    if tbl.foot and tbl.foot.rows then
        for _, row in ipairs(tbl.foot.rows) do
            for i, cell in ipairs(row.cells) do
                row.cells[i] = simplify_cell(cell)
            end
        end
    end

    -- Keep colspecs but set widths to 0 (tables need column structure)
    -- Post-processing script will convert HTML tables to pipe tables
    for i, colspec in ipairs(tbl.colspecs) do
        tbl.colspecs[i] = {colspec[1], 0.0}
    end

    return tbl
end
