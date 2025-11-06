-- convert-underline.lua
-- Convert [text]{.underline} and Underline elements to special markers that survive GFM conversion
-- These markers are later converted to <u> tags in post-processing

-- Handle Underline elements from DOCX
function Underline(elem)
  -- Use special Unicode markers that won't appear in normal text
  -- ⟪U⟫ and ⟪/U⟫ are unlikely to appear in technical documentation
  local content = pandoc.utils.stringify(elem.content)
  return pandoc.Str("⟪U⟫" .. content .. "⟪/U⟫")
end

-- Handle Span elements with underline class
function Span(span)
  -- Check if this span has the underline class
  if span.classes and span.classes:includes("underline") then
    -- Use the same marker approach
    local content = pandoc.utils.stringify(span.content)
    return pandoc.Str("⟪U⟫" .. content .. "⟪/U⟫")
  end

  return span
end

-- Also handle any remaining [text]{.underline} patterns in raw text
function Str(str)
  -- Replace any remaining [text]{.underline} patterns with <u>text</u>
  local text = str.text
  text = text:gsub("%[([^%]]+)%]%{%.underline%}", "<u>%1</u>")
  return pandoc.Str(text)
end

-- NOTE: Removed the Pandoc() function that was doing round-trip markdown conversion
-- because it was destroying table structures (converting <thead> to <tbody> with H1 tags).
-- The Span() and Str() functions above are sufficient for handling underline conversion.