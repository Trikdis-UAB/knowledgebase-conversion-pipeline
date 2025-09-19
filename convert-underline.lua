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

-- Post-process the entire document to catch any remaining patterns
function Pandoc(doc)
  -- Convert the document to string, fix underline patterns, then back
  local content = pandoc.write(doc, "markdown")

  -- Fix remaining [text]{.underline} patterns
  content = content:gsub("%[([^%]]+)%]%{%.underline%}", "<u>%1</u>")

  -- Parse back to Pandoc document
  return pandoc.read(content, "markdown")
end