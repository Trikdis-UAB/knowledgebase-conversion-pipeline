-- force-markdown-tables.lua
-- Forces simple tables to be output as markdown pipe tables instead of HTML
-- Only applies to tables with simple structure (no rowspan, no multi-paragraph cells)

function Table(tbl)
    -- Check if this is a simple table that can be represented in markdown
    local is_simple = true

    -- Check if table has complex attributes
    if tbl.caption and #tbl.caption > 0 then
        -- Tables with captions need HTML
        is_simple = false
    end

    -- Check all rows for complex content
    for _, row in ipairs(tbl.head.rows) do
        for _, cell in ipairs(row.cells) do
            -- Check if cell has multiple blocks or non-Plain/Para blocks
            if #cell.contents > 1 then
                is_simple = false
                break
            end
            for _, block in ipairs(cell.contents) do
                if block.t ~= 'Plain' and block.t ~= 'Para' then
                    is_simple = false
                    break
                end
            end
        end
        if not is_simple then break end
    end

    for _, body in ipairs(tbl.bodies) do
        for _, row in ipairs(body.body) do
            for _, cell in ipairs(row.cells) do
                -- Check if cell has multiple blocks
                if #cell.contents > 1 then
                    is_simple = false
                    break
                end
                for _, block in ipairs(cell.contents) do
                    if block.t ~= 'Plain' and block.t ~= 'Para' then
                        is_simple = false
                        break
                    end
                end
            end
            if not is_simple then break end
        end
        if not is_simple then break end
    end

    -- If simple, mark it for markdown output by removing style attributes
    if is_simple then
        -- Remove any style attributes that might force HTML output
        tbl.attr = pandoc.Attr("", {}, {})
    end

    return tbl
end
