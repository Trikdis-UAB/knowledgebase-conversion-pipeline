-- fix-typography.lua
-- Typography cleanup for DOCX to Markdown conversion
-- 1. Convert backticks to proper apostrophes
-- 2. Remove empty bold formatting artifacts

function Str(el)
  -- Convert backticks to apostrophes
  el.text = el.text:gsub("`", "'")
  return el
end

function Strong(el)
  -- Check if this Strong element contains only whitespace
  local text = pandoc.utils.stringify(el.content)

  -- Remove empty bold formatting: "**  **" or "**\s+**"
  if text:match("^%s*$") then
    return {}  -- Remove this element entirely
  end

  return el  -- Keep normal bold formatting
end