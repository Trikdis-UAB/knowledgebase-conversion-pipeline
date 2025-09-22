-- strip-manual-heading-numbers.lua
-- Removes manually written numbers from headings before automatic numbering
-- This prevents conflicts like "4. 4.2 Programming..." when auto-numbering is applied

-- Pattern to match manual heading numbers at the start of heading text
-- Matches patterns like: "1.", "1.1", "1.1.1", "4.2", etc.
-- Fixed pattern: digit(s), optionally followed by dot+digit(s), optionally ending with dot, then space
local MANUAL_NUMBER_PATTERN = "^%d+%.?%d*%.?%d*%.?%s+"


-- Main filter function
function Header(header)
    -- Use pandoc.utils.stringify to get the full text
    local text = pandoc.utils.stringify(header.content)

    -- Check if this looks like a manual number and remove it
    local cleaned = text:gsub(MANUAL_NUMBER_PATTERN, "")

    if cleaned ~= text then
        -- Found and removed manual numbering
        print("Cleaned heading: '" .. text .. "' -> '" .. cleaned .. "'")
        -- Replace the entire content with cleaned text
        header.content = {pandoc.Str(cleaned)}
    end

    return header
end