-- move-first-image-to-description.lua
-- Move the first image in the document to immediately after the "Description" heading

local first_image = nil
local first_image_index = nil
local description_heading_index = nil
local blocks = {}

-- First pass: collect all blocks and find the first image and Description heading
function Pandoc(doc)
  blocks = doc.blocks

  for i, block in ipairs(blocks) do
    -- Find the first image (various formats)
    if not first_image then
      if block.t == "Para" and #block.content == 1 and block.content[1].t == "Image" then
        first_image = block
        first_image_index = i
      elseif block.t == "RawBlock" and block.format == "html" and block.text:match("<img[^>]*>") then
        first_image = block
        first_image_index = i
      elseif block.t == "Para" and #block.content == 1 and block.content[1].t == "RawInline" and
             block.content[1].format == "html" and block.content[1].text:match("<img[^>]*>") then
        first_image = block
        first_image_index = i
      elseif block.t == "CodeBlock" and block.text:match("<img[^>]*>") then
        first_image = block
        first_image_index = i
      end
    end

    -- Find Description heading (level 2)
    if block.t == "Header" and block.level == 2 then
      local heading_text = pandoc.utils.stringify(block.content):lower()
      if heading_text:match("description") then
        description_heading_index = i
      end
    end
  end

  -- If we found both the first image and the Description heading
  if first_image and first_image_index and description_heading_index then
    -- Only move if the image is not already before the Description heading
    if first_image_index ~= description_heading_index - 1 then
      -- Remove the image from its current position
      table.remove(blocks, first_image_index)

      -- Adjust description_heading_index if needed
      if first_image_index < description_heading_index then
        description_heading_index = description_heading_index - 1
      end

      -- Wrap the image in a centered div
      local centered_image
      if first_image.t == "Para" and #first_image.content == 1 and first_image.content[1].t == "RawInline" then
        -- Handle RawInline HTML images
        local img_html = first_image.content[1].text
        centered_image = pandoc.RawBlock("html",
          '<div style="text-align: center;">\n' .. img_html .. '\n</div>')
      elseif first_image.t == "CodeBlock" then
        -- Handle CodeBlock HTML images
        local img_html = first_image.text:gsub("`", ""):gsub("{=html}", "")
        centered_image = pandoc.RawBlock("html",
          '<div style="text-align: center;">\n' .. img_html .. '\n</div>')
      else
        -- Handle regular images and raw HTML blocks
        centered_image = pandoc.RawBlock("html",
          '<div style="text-align: center;">\n<img alt="" src="./image3.png" style="width:2.36in;height:3.44in" />\n</div>')
      end

      -- Insert the centered image right before the Description heading
      table.insert(blocks, description_heading_index, centered_image)
    end
  end

  return pandoc.Pandoc(blocks, doc.meta)
end