-- maintain-list-continuity.lua
-- Maintains numbered list continuity across interruptions (images, headers, etc.)

local list_counter = 0
local in_continuous_list = false
local last_list_number = 0

-- Helper function to check if an element interrupts lists but shouldn't reset numbering
local function is_list_interruption(elem)
    if elem.t == "Para" then
        -- Check if paragraph contains only an image
        if #elem.content == 1 and elem.content[1].t == "Image" then
            return true
        end
        -- Check if paragraph contains only formatting (like **text**)
        local text = pandoc.utils.stringify(elem)
        if text:match("^%*%*.*%*%*$") or text:match("^In \".*\" window") then
            return true
        end
    elseif elem.t == "RawBlock" and elem.format == "html" then
        -- HTML images
        if elem.text:match("<img") then
            return true
        end
    elseif elem.t == "HorizontalRule" then
        return true
    end
    return false
end

-- Helper function to check if we should reset list numbering
local function should_reset_list(elem)
    if elem.t == "Header" and elem.level <= 3 then
        return true
    elseif elem.t == "Para" then
        local text = pandoc.utils.stringify(elem)
        -- Reset for major section changes
        if text:match("^%*%*%*[%w%s]+%*%*%*$") then -- ***SECTION*** format
            return true
        end
    end
    return false
end

function Pandoc(doc)
    local new_blocks = {}
    local i = 1

    while i <= #doc.blocks do
        local elem = doc.blocks[i]

        if elem.t == "OrderedList" then
            if in_continuous_list then
                -- Continue numbering from where we left off
                last_list_number = last_list_number + #elem.content
                elem.start = last_list_number - #elem.content + 1
            else
                -- Start new list
                in_continuous_list = true
                last_list_number = #elem.content
                -- Keep original start number if specified, otherwise default to 1
                if not elem.start then
                    elem.start = 1
                end
            end
            table.insert(new_blocks, elem)

        elseif should_reset_list(elem) then
            -- Reset list tracking for major sections
            in_continuous_list = false
            last_list_number = 0
            table.insert(new_blocks, elem)

        elseif is_list_interruption(elem) then
            -- Keep list context but don't reset
            table.insert(new_blocks, elem)

        else
            -- For other elements, check if we should continue list context
            local text = pandoc.utils.stringify(elem)

            -- Continue context for certain patterns
            if not (text:match("^$") or  -- empty
                   text:match("After finishing") or  -- end of section
                   elem.t == "CodeBlock" or
                   elem.t == "Div") then
                -- Reset for substantial content that's not list-related
                if #text > 50 and not text:match("settings") and not text:match("window") then
                    in_continuous_list = false
                    last_list_number = 0
                end
            end

            table.insert(new_blocks, elem)
        end

        i = i + 1
    end

    return pandoc.Pandoc(new_blocks, doc.meta)
end