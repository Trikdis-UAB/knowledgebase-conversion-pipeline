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
    -- Check if image is already before Description heading
    local already_positioned = (first_image_index == description_heading_index - 1)

    if not already_positioned then
      -- Remove the image from its current position
      table.remove(blocks, first_image_index)

      -- Adjust description_heading_index if needed
      if first_image_index < description_heading_index then
        description_heading_index = description_heading_index - 1
      end
    end

    -- Wrap the image in a centered div with consistent width (whether moving or reformatting in place)
      local centered_image
      if first_image.t == "Para" and #first_image.content == 1 and first_image.content[1].t == "Image" then
        -- Handle markdown images: ![alt](src)
        local img = first_image.content[1]
        local alt = pandoc.utils.stringify(img.caption)
        local src = img.src
        centered_image = pandoc.RawBlock("html",
          '<div style="text-align: center;">\n  <img src="' .. src .. '" alt="' .. alt .. '" width="400">\n</div>')
      elseif first_image.t == "Para" and #first_image.content == 1 and first_image.content[1].t == "RawInline" then
        -- Handle RawInline HTML images
        local img_html = first_image.content[1].text
        -- Add width="400" if not present
        if not img_html:match('width=') then
          img_html = img_html:gsub('(<img[^>]*)', '%1 width="400"')
        end
        centered_image = pandoc.RawBlock("html",
          '<div style="text-align: center;">\n  ' .. img_html .. '\n</div>')
      elseif first_image.t == "CodeBlock" then
        -- Handle CodeBlock HTML images
        local img_html = first_image.text:gsub("`", ""):gsub("{=html}", "")
        -- Add width="400" if not present
        if not img_html:match('width=') then
          img_html = img_html:gsub('(<img[^>]*)', '%1 width="400"')
        end
        centered_image = pandoc.RawBlock("html",
          '<div style="text-align: center;">\n  ' .. img_html .. '\n</div>')
      elseif first_image.t == "RawBlock" and first_image.format == "html" then
        -- Handle raw HTML blocks
        local img_html = first_image.text
        -- Add width="400" if not present
        if not img_html:match('width=') then
          img_html = img_html:gsub('(<img[^>]*)', '%1 width="400"')
        end
        centered_image = pandoc.RawBlock("html",
          '<div style="text-align: center;">\n  ' .. img_html .. '\n</div>')
      else
        -- Fallback: create default centered image
        centered_image = pandoc.RawBlock("html",
          '<div style="text-align: center;">\n  <img src="./image1.png" alt="" width="400">\n</div>')
      end

    -- Insert or replace the centered image
    if already_positioned then
      -- Replace the existing image in place
      blocks[first_image_index] = centered_image
    else
      -- Insert the centered image right before the Description heading
      table.insert(blocks, description_heading_index, centered_image)
    end
  end

  return pandoc.Pandoc(blocks, doc.meta)
end