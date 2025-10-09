-- convert-underline.lua
-- Convert [text]{.underline} to proper HTML <u>text</u> tags

function Span(span)
  -- Check if this span has the underline class
  if span.classes and span.classes:includes("underline") then
    -- Convert to HTML underline tag
    local content = pandoc.utils.stringify(span.content)
    return pandoc.RawInline("html", "<u>" .. content .. "</u>")
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