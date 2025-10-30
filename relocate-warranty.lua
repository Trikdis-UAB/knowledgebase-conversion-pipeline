--[[
Relocate Warranty Sections Filter

This filter extracts warranty/safety requirement sections from the beginning of the document
(after TOC, before Description) and moves them to the end as a final H2 chapter.

Two patterns exist:
1. Communicators (GET, GT, GT+): "Safety requirements" - brief section
2. Alarm Panels (SP3): "Warranty and limitation of liability" - detailed section

Multi-language support for section headings.

This filter should run LAST in the pipeline to ensure the warranty section ends up at the bottom.
]]

-- Warranty section heading patterns (case-insensitive)
local warranty_patterns = {
  -- English
  "^safety requirements$",
  "^safety precautions$",
  "^warranty and limitation of liability$",
  -- Lithuanian
  "^saugos reikalavimai$",
  "^saugos atsargumo priemonės$",
  "^garantija ir atsakomybės apribojimas$",
  -- Spanish
  "^requisitos de seguridad$",
  "^requerimientos de seguridad$",
  "^precauciones de seguridad$",
  "^garantía y limitación de responsabilidad$",
  -- Russian
  "^требования безопасности$",
  "^меры предосторожности$",
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
  -- Trim whitespace before matching
  local lower_text = text:lower():match("^%s*(.-)%s*$")
  for _, pattern in ipairs(warranty_patterns) do
    if lower_text:match(pattern) then
      return true
    end
  end
  return false
end

-- Check if heading indicates end of warranty section
local function is_stop_heading(text)
  -- Trim whitespace before matching
  local lower_text = text:lower():match("^%s*(.-)%s*$")
  for _, pattern in ipairs(stop_patterns) do
    if lower_text:match(pattern) then
      return true
    end
  end
  return false
end

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

function Pandoc(doc)
  local filtered_blocks = {}
  local warranty_content = {}
  local warranty_heading = nil
  local in_warranty_section = false

  -- First pass: collect warranty content and build filtered document
  for i, block in ipairs(doc.blocks) do
    -- Check for warranty section as bold paragraph
    local warranty_title = is_warranty_paragraph(block)
    if warranty_title then
      if not in_warranty_section then
        -- First warranty section - start collecting
        in_warranty_section = true
        warranty_heading = pandoc.Header(2, {pandoc.Str(warranty_title)})
        warranty_content = {}
      else
        -- Subsequent warranty section - add as separate H2 heading
        table.insert(warranty_content, pandoc.Para{})  -- Blank line before
        table.insert(warranty_content, pandoc.Header(2, {pandoc.Str(warranty_title)}))
      end
      -- Don't add to filtered_blocks - we'll append at end
      goto continue
    end

    if block.t == "Header" then
      local heading_text = pandoc.utils.stringify(block)

      -- Check if this is a warranty heading (as H1 or H2 header, not bold paragraph)
      if (block.level == 1 or block.level == 2) and is_warranty_heading(heading_text) and not in_warranty_section then
        in_warranty_section = true
        -- Always use H2 for warranty heading at the end
        warranty_heading = pandoc.Header(2, block.content)
        warranty_content = {}
        -- Don't add to filtered_blocks - we'll append at end
        goto continue
      end

      -- Check if this ends the warranty section
      if in_warranty_section and is_stop_heading(heading_text) then
        in_warranty_section = false
      end

      -- If we're in warranty section and hit another header, end section
      if in_warranty_section and block.level <= 2 and not is_warranty_heading(heading_text) then
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

  -- Second pass: insert warranty section before Annex or at end
  if warranty_heading and #warranty_content > 0 then
    -- Find Annex section (H2 heading with "Annex" text)
    local annex_index = nil
    for i, block in ipairs(filtered_blocks) do
      if block.t == "Header" and block.level == 2 then
        local heading_text = pandoc.utils.stringify(block):lower()
        if heading_text:match("^annex") or heading_text:match("^priedas") or
           heading_text:match("^anexo") or heading_text:match("^приложение") then
          annex_index = i
          break
        end
      end
    end

    -- Prepare warranty blocks to insert
    local warranty_blocks = {}
    table.insert(warranty_blocks, pandoc.Para{})  -- Blank line before
    table.insert(warranty_blocks, warranty_heading)  -- H2 heading
    for _, block in ipairs(warranty_content) do
      table.insert(warranty_blocks, block)  -- Content
    end

    -- Insert before Annex if found, otherwise append at end
    if annex_index then
      -- Insert warranty before Annex
      for i = #warranty_blocks, 1, -1 do
        table.insert(filtered_blocks, annex_index, warranty_blocks[i])
      end
    else
      -- No Annex, append at end
      for _, block in ipairs(warranty_blocks) do
        table.insert(filtered_blocks, block)
      end
    end
  end

  -- Return document with warranty section relocated
  doc.blocks = filtered_blocks
  return doc
end

return {
  {Pandoc = Pandoc}
}
