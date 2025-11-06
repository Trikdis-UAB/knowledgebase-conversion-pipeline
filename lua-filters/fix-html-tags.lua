-- fix-html-tags.lua
-- Cleans up problematic HTML tags from DOCX conversion
--
-- Handles:
-- 1. Pandoc Subscript elements → [text] in code formatting
-- 2. <sub>space</sub> HTML → [space] in code formatting
-- 3. <sup>text</sup> → superscript cleanup if needed
-- 4. Other HTML tag artifacts that should be plain text

local S = pandoc.utils.stringify

-- Handle Pandoc's Subscript inline element
function Subscript(el)
  -- Convert subscript content to [content] in code format
  local content = S(el.content)

  -- Special case: if it's just "space" or similar placeholder, use brackets
  if content:match("^space$") or content:match("^tab$") or content:match("^enter$") then
    return pandoc.Code("[" .. content .. "]")
  end

  -- For other subscripts, convert to regular subscript notation
  -- or keep as bracketed text
  return pandoc.Code("[" .. content .. "]")
end

-- Handle Pandoc's Superscript inline element (if needed)
function Superscript(el)
  local content = S(el.content)
  -- Keep superscripts as is for now, or convert if needed
  return el
end

-- Handle raw HTML subscript/superscript tags
function RawInline(el)
  if el.format ~= 'html' then
    return el
  end

  local html = el.text

  -- Pattern 1: <sub>text</sub> → convert to [text] in code
  local sub_content = html:match("<sub>([^<]+)</sub>")
  if sub_content then
    return pandoc.Code("[" .. sub_content .. "]")
  end

  -- Pattern 2: <sup>text</sup> → keep for now
  -- Can expand later if needed

  return el
end
