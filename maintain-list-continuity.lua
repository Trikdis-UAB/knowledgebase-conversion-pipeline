-- maintain-list-continuity.lua
-- Maintains numbered list continuity across interruptions (images, headers, etc.)
-- This filter preserves semantic markdown while ensuring proper numbering sequence

local list_state = {
    counter = 0,
    in_continuous_list = false,
    section_context = ""
}

-- Patterns that indicate list continuation context
local CONTINUATION_PATTERNS = {
    "^In \".*\" window",
    "^%*%*In \".*\" window",
    "settings",
    "window:",
    "tab:",
    "group"
}

-- Patterns that indicate major section breaks (reset numbering)
local RESET_PATTERNS = {
    "^###", -- H3 headers
    "^##",  -- H2 headers
    "%*%*%*[%w%s]+%*%*%*", -- ***SECTION*** format (anywhere in text)
    "After finishing configuration",
    "Installation and wiring",
    "Programming the control panel"
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
local function should_reset_list(elem)
    if elem.t == "Header" and elem.level <= 3 then
        return true
    elseif elem.t == "Para" then
        local text = pandoc.utils.stringify(elem)
        for _, pattern in ipairs(RESET_PATTERNS) do
            if text:match(pattern) then
                return true
            end
        end
    end
    return false
end

-- Helper: Detect section context for smarter continuation
local function get_section_context(elem)
    if elem.t == "Para" then
        local text = pandoc.utils.stringify(elem)
        if text:match("Settings for connection with") then
            return text
        elseif text:match("In \".*\" window") then
            return text
        end
    elseif elem.t == "Header" then
        return pandoc.utils.stringify(elem)
    end
    return ""
end

-- Main filter function
function Pandoc(doc)
    local new_blocks = {}

    for i, elem in ipairs(doc.blocks) do
        -- Update section context
        local context = get_section_context(elem)
        if context ~= "" then
            list_state.section_context = context
        end

        if elem.t == "OrderedList" then
            if list_state.in_continuous_list then
                -- Continue numbering from where we left off
                list_state.counter = list_state.counter + #elem.content
                elem.start = list_state.counter - #elem.content + 1

            else
                -- Start new list sequence
                list_state.in_continuous_list = true
                list_state.counter = #elem.content
                elem.start = elem.start or 1

            end

            table.insert(new_blocks, elem)

        elseif should_reset_list(elem) then
            -- Reset list tracking for major sections
            list_state.in_continuous_list = false
            list_state.counter = 0
            list_state.section_context = ""

            table.insert(new_blocks, elem)

        elseif is_list_interruption(elem) then
            -- Keep list context active but don't reset
            table.insert(new_blocks, elem)

        else
            -- Check if this element should break list context
            local text = pandoc.utils.stringify(elem)

            -- Continue context for empty elements, notes, etc.
            if text:match("^%s*$") or
               text:match("^!!! note") or
               text:match("After finishing configuration") or
               elem.t == "CodeBlock" or
               elem.t == "Div" then
                -- Keep context
            else
                -- Check for major section breaks (like "MAJOR SECTION BREAK")
                if text:match("MAJOR.*SECTION.*BREAK") or
                   text:match("SECTION BREAK") then
                    list_state.in_continuous_list = false
                    list_state.counter = 0
                -- For other substantial content, be conservative
                elseif #text > 100 and
                   not text:match("settings") and
                   not text:match("window") and
                   not text:match("configuration") then
                    list_state.in_continuous_list = false
                    list_state.counter = 0
                end
            end

            table.insert(new_blocks, elem)
        end
    end

    return pandoc.Pandoc(new_blocks, doc.meta)
end