--[[
Remove standalone **** markers that are NOT inside tables.

In DOCX manuals, sometimes standalone lines with **** appear as section separators
or artifacts. These should be removed. However, **** inside tables are placeholders
for configuration codes and must be preserved.

This filter removes Para blocks that contain only "****" text.
Table cells are handled by the Table function which preserves all content.
]]

-- Track if we're inside a table
local in_table = false

function Table(tbl)
    -- Mark that we're processing a table
    in_table = true

    -- Process the table (this will preserve all cell content including ****)
    local result = pandoc.walk_block(tbl, {
        Para = function(para)
            -- Inside tables, preserve ALL paragraphs including ****
            return para
        end
    })

    -- Reset the flag after table processing
    in_table = false
    return result
end

function Para(para)
    -- If we're inside a table, preserve everything
    if in_table then
        return para
    end

    -- Check if this paragraph contains only "****"
    if #para.content == 1 and para.content[1].t == "Str" then
        local text = para.content[1].text
        -- Remove if it's exactly "****" (escaped as \*\*\*\* in some cases)
        if text == "****" or text == "\\*\\*\\*\\*" then
            return {}  -- Remove this paragraph
        end
    end

    return para
end

-- Return the filters in order
return {
    {Table = Table},
    {Para = Para}
}
