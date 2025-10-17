--[[
Fix heading levels based on numbered structure.

Analyzes heading numbers like "11.1 Title" or "11.1.1 Title" and sets
the proper heading level based on the number of dots.

Rules:
- "11. Title" or "Title" without dots -> H2 (main section)
- "11.1 Title" (1 dot) -> H3 (subsection)
- "11.1.1 Title" (2 dots) -> H4 (sub-subsection)
- "11.1.1.1 Title" (3 dots) -> H5

Exception: Skip if it looks like a list item (short, ends with period at end of line)
]]

local function count_dots(str)
    local count = 0
    for _ in str:gmatch("%.") do
        count = count + 1
    end
    return count
end

local function is_numbered_heading(str)
    -- Match patterns like "11. Title" or "11.1 Title" or "11.1.1 Title"
    -- Must have text after the number
    return str:match("^%s*%d+[%.%d]*%.?%s+%S+")
end

local function get_number_prefix(str)
    -- Extract the number part: "11.1 Title" -> "11.1"
    local num = str:match("^%s*(%d+[%.%d]*)%.?%s+")
    return num
end

function Header(el)
    local text = pandoc.utils.stringify(el.content)

    -- Check if this is a numbered heading
    if not is_numbered_heading(text) then
        return el
    end

    -- Get the number prefix
    local num_prefix = get_number_prefix(text)
    if not num_prefix then
        return el
    end

    -- Count dots to determine level
    local dots = count_dots(num_prefix)

    -- Determine target level:
    -- 0 dots (e.g., "11") -> H2
    -- 1 dot (e.g., "11.1") -> H3
    -- 2 dots (e.g., "11.1.1") -> H4
    -- 3+ dots -> H5 (max)
    local target_level = 2 + dots
    if target_level > 5 then
        target_level = 5
    end

    -- Only modify if different from current level
    if el.level ~= target_level then
        el.level = target_level
    end

    return el
end

return {{Header = Header}}
