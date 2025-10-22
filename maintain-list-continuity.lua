-- maintain-list-continuity.lua
-- Maintains numbered list continuity across interruptions (images, headers, etc.)
-- Algorithm: "if there is a singular numbered item, it is a part of a previous list,
--            unless there was a new heading, then this is a new list"

local list_state = {
    counter = 0,
    in_continuous_list = false,
    last_was_admonition = false  -- Track if previous list was inside admonition
}

-- Patterns that indicate list continuation context (images, short context text)
local CONTINUATION_PATTERNS = {
    "^In \".*\" window",
    "^%*%*In \".*\" window",
    "settings",
    "window:",
    "tab:",
    "group"
}

-- Helper: Check if element is a list interruption (continue context)
local function is_list_interruption(elem)
    if elem.t == "Para" then
        -- Single image in paragraph
        if #elem.content == 1 and elem.content[1].t == "Image" then
            return true
        end

        -- Section headers that continue context
        local text = pandoc.utils.stringify(elem)
        for _, pattern in ipairs(CONTINUATION_PATTERNS) do
            if text:match(pattern) then
                return true
            end
        end

        -- Empty or minimal formatting
        if text:match("^%s*$") or text:match("^%*%*%s*%*%*$") then
            return true
        end
    elseif elem.t == "RawBlock" and elem.format == "html" then
        -- HTML images from DOCX conversion
        if elem.text:match("<img") then
            return true
        end
    elseif elem.t == "HorizontalRule" then
        return true
    end
    return false
end

-- Helper: Check if we should reset list numbering
-- User's algorithm: ANY heading resets list numbering
local function should_reset_list(elem)
    -- ANY heading (H2, H3, H4, H5, H6) resets numbering
    if elem.t == "Header" then
        return true
    end
    return false
end

-- Helper: Check if element is an admonition (note, warning, tip, etc.)
local function is_admonition(elem)
    if elem.t == "Div" then
        -- Pandoc represents admonitions as Div elements
        for _, class in ipairs(elem.classes or {}) do
            if class == "note" or class == "warning" or class == "tip" or
               class == "important" or class == "caution" then
                return true
            end
        end
    end
    return false
end

-- Helper: Check if admonition contains an ordered list
local function admonition_has_list(elem)
    if not is_admonition(elem) then
        return false
    end

    -- Check if any content block is an OrderedList
    for _, block in ipairs(elem.content or {}) do
        if block.t == "OrderedList" then
            return true
        end
    end
    return false
end

-- Main filter function
-- Implements user's algorithm: "if there is a singular numbered item, it is a part
-- of a previous list, unless there was a new heading, then this is a new list"
function Pandoc(doc)
    local new_blocks = {}

    for i, elem in ipairs(doc.blocks) do
        if elem.t == "Header" then
            -- ANY heading resets list numbering
            list_state.in_continuous_list = false
            list_state.counter = 0
            list_state.last_was_admonition = false
            table.insert(new_blocks, elem)

        elseif elem.t == "OrderedList" then
            -- Handle ordered lists
            if list_state.in_continuous_list then
                -- Continue numbering from where we left off
                local start_num = list_state.counter + 1
                elem.start = start_num
                list_state.counter = start_num + #elem.content - 1
            else
                -- Start new list sequence
                list_state.in_continuous_list = true
                list_state.counter = #elem.content
                elem.start = 1
            end
            list_state.last_was_admonition = false
            table.insert(new_blocks, elem)

        elseif is_admonition(elem) then
            -- Process admonitions - they may contain lists
            if admonition_has_list(elem) then
                -- Find and update the list inside the admonition
                for _, block in ipairs(elem.content or {}) do
                    if block.t == "OrderedList" then
                        if list_state.in_continuous_list then
                            -- Continue from previous list
                            local start_num = list_state.counter + 1
                            block.start = start_num
                            list_state.counter = start_num + #block.content - 1
                        else
                            -- Start new sequence
                            list_state.in_continuous_list = true
                            list_state.counter = #block.content
                            block.start = 1
                        end
                        list_state.last_was_admonition = true
                    end
                end
            end
            table.insert(new_blocks, elem)

        elseif is_list_interruption(elem) then
            -- Images, short context text, etc. - keep list context active
            table.insert(new_blocks, elem)

        else
            -- Any other element (paragraphs, code blocks, etc.)
            -- Keep list context active unless it's substantial content
            table.insert(new_blocks, elem)
        end
    end

    return pandoc.Pandoc(new_blocks, doc.meta)
end