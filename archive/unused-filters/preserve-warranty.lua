--[[
Preserve Warranty Sections Filter

This filter runs BEFORE strip-cover.lua to extract warranty and safety requirement
sections from DOCX manuals. These sections appear after the TOC but before the main
content and are currently being stripped unintentionally.

Two patterns exist:
1. Communicators (GET, GT, GT+): "Safety requirements" - brief section
2. Alarm Panels (SP3): "Warranty and limitation of liability" - detailed section

The content is stored in document metadata and will be appended to the end
of the document by the append-warranty.lua filter (which runs last).

Multi-language support for section headings.
]]

-- Warranty section heading patterns (case-insensitive)
local warranty_patterns = {
  -- English
  "^safety requirements$",
  "^warranty and limitation of liability$",
  -- Lithuanian
  "^saugos reikalavimai$",
  "^garantija ir atsakomybės apribojimas$",
  -- Spanish
  "^requisitos de seguridad$",
  "^garantía y limitación de responsabilidad$",
  -- Russian
  "^требования безопасности$",
  "^гарантия и ограничение ответственности$",
}

-- Stop patterns that indicate end of warranty section
local stop_patterns = {
  "^description$",
  "^aprašymas$",  -- Lithuanian
  "^descripción$",  -- Spanish
  "^описание$",  -- Russian
}

-- Check if heading matches any warranty pattern
local function is_warranty_heading(text)
  local lower_text = text:lower()
  for _, pattern in ipairs(warranty_patterns) do
    if lower_text:match(pattern) then
      return true
    end
  end
  return false
end

-- Check if heading indicates end of warranty section
local function is_stop_heading(text)
  local lower_text = text:lower()
  for _, pattern in ipairs(stop_patterns) do
    if lower_text:match(pattern) then
      return true
    end
  end
  return false
end

-- Extract plain text from Inlines
local function inlines_to_text(inlines)
  local text = {}
  for _, inline in ipairs(inlines) do
    if inline.t == "Str" then
      table.insert(text, inline.text)
    elseif inline.t == "Space" then
      table.insert(text, " ")
    end
  end
  return table.concat(text)
end

-- State tracking
local in_warranty_section = false
local warranty_content = {}
local warranty_heading = nil

-- Check if paragraph contains bold text matching warranty patterns
local function is_warranty_paragraph(block)
  if block.t ~= "Para" then
    return false
  end

  for _, inline in ipairs(block.content) do
    if inline.t == "Strong" then
      local text = pandoc.utils.stringify(inline)
      if is_warranty_heading(text) then
        return text  -- Return the warranty heading text
      end
    end
  end
  return false
end

-- Process document blocks
function Pandoc(doc)
  local filtered_blocks = {}

  for i, block in ipairs(doc.blocks) do
    -- Check for warranty section as bold paragraph
    local warranty_title = is_warranty_paragraph(block)
    if warranty_title then
      in_warranty_section = true
      -- Create H2 heading from the bold text
      warranty_heading = pandoc.Header(2, {pandoc.Str(warranty_title)})
      warranty_content = {}
      -- Don't add to filtered_blocks - we'll append at end
      goto continue
    end

    if block.t == "Header" then
      local heading_text = pandoc.utils.stringify(block)

      -- Check if this ends the warranty section
      if in_warranty_section and is_stop_heading(heading_text) then
        in_warranty_section = false
      end

      -- If we're in warranty section and hit another header, end section
      if in_warranty_section and block.level <= 2 then
        in_warranty_section = false
      end
    end

    -- If in warranty section, store the content
    if in_warranty_section then
      table.insert(warranty_content, block)
      -- Don't add to filtered_blocks
      goto continue
    end

    -- Not in warranty section, keep the block
    table.insert(filtered_blocks, block)

    ::continue::
  end

  -- Store warranty content in metadata for append-warranty.lua
  if warranty_heading and #warranty_content > 0 then
    -- Store as plain Lua tables, not Pandoc objects
    doc.meta['warranty_heading_text'] = pandoc.MetaString(pandoc.utils.stringify(warranty_heading))
    doc.meta['warranty_heading_level'] = pandoc.MetaString(tostring(warranty_heading.level))

    -- Store content blocks as a list in metadata
    local content_list = {}
    for i, block in ipairs(warranty_content) do
      content_list[i] = block
    end
    doc.meta['warranty_blocks'] = pandoc.MetaBlocks(content_list)
  else
  end

  -- Return document without warranty sections (they're in metadata now)
  doc.blocks = filtered_blocks
  return doc
end

return {
  {Pandoc = Pandoc}
}
