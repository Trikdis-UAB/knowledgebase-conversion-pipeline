--[[
  promote-centered-bold.lua

  Converts emphasized bold paragraphs (italic+bold) into subheaders.
  These appear in DOCX as centered, bold text representing subsections
  (e.g., manufacturer names like "DSC", "PARADOX", "TEXECOM").

  In the Pandoc AST, they appear as: Para [ Emph [ Strong [ Str "..." ] ] ]

  The filter tracks the current heading level and promotes these
  paragraphs to one level deeper than the current section.
]]

local current_heading_level = 2  -- Start at H2 (main sections)

function Header(el)
  -- Track the current heading level as we traverse the document
  current_heading_level = el.level
  return el
end

function Para(el)
  -- Check for pattern: Para with single Emph containing Strong
  -- This is how centered bold text from DOCX appears in Pandoc AST
  local is_emph_strong = false
  local text_content = ""
  local inner_content = {}

  if #el.content == 1 and el.content[1].t == "Emph" then
    local emph = el.content[1]
    -- Check if Emph contains Strong
    if #emph.content == 1 and emph.content[1].t == "Strong" then
      is_emph_strong = true
      text_content = pandoc.utils.stringify(emph.content[1])
      -- Extract the actual text content from Strong
      inner_content = emph.content[1].content
    end
  end

  -- Also check for centered alignment (backup method)
  local is_centered = false
  if el.attr and el.attr.attributes then
    local align = el.attr.attributes['align'] or el.attr.attributes['text-align']
    if align == 'center' or align == 'Center' then
      is_centered = true
    end
  end

  -- Check if entire paragraph content is bold/strong (another backup method)
  local is_bold = false
  if #el.content == 1 and el.content[1].t == "Strong" then
    is_bold = true
    text_content = pandoc.utils.stringify(el.content[1])
    inner_content = el.content[1].content
  end

  -- Convert to subheader if it matches any pattern
  if (is_emph_strong or (is_centered and is_bold)) and text_content ~= "" and #text_content < 100 then
    -- Create heading one level deeper than current section
    local new_level = math.min(current_heading_level + 1, 6)  -- Max H6

    return pandoc.Header(new_level, inner_content)
  end

  return el
end

-- Return single filter that processes both in document order
return {
  {Header = Header, Para = Para}
}
