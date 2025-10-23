-- move-first-image-to-description.lua
-- Move the first image to immediately after the H1 title (before Description heading)
-- Removes ALL standalone images before Description to avoid duplicates

-- Debug log function (disabled for production)
local function debug_log(msg)
  -- Disabled
end

local first_image = nil
local first_image_index = nil
local h1_index = nil
local description_index = nil
local blocks = {}
local image_indices = {}  -- Track ALL image indices to remove

-- First pass: collect all blocks and find images, H1 title, and Description heading
function Pandoc(doc)
  blocks = doc.blocks

  for i, block in ipairs(blocks) do
    -- Track all standalone images (we'll remove them all before Description)
    local is_image = false
    if block.t == "Para" and #block.content == 1 and block.content[1].t == "Image" then
      is_image = true
      if not first_image then
        first_image = block
        first_image_index = i
      end
    elseif block.t == "RawBlock" and block.format == "html" and block.text:match("<img[^>]*>") then
      is_image = true
      if not first_image then
        first_image = block
        first_image_index = i
      end
    elseif block.t == "Para" and #block.content == 1 and block.content[1].t == "RawInline" and
           block.content[1].format == "html" and block.content[1].text:match("<img[^>]*>") then
      is_image = true
      if not first_image then
        first_image = block
        first_image_index = i
      end
    elseif block.t == "CodeBlock" and block.text:match("<img[^>]*>") then
      is_image = true
      if not first_image then
        first_image = block
        first_image_index = i
      end
    end

    -- Track this image index for removal
    if is_image then
      table.insert(image_indices, i)
      -- Try to get image src for debugging
      if block.t == "Para" and #block.content == 1 and block.content[1].t == "Image" then
        debug_log("Found image at index " .. i .. ": " .. block.content[1].src)
      else
        debug_log("Found image at index " .. i .. " (non-Para format)")
      end
    end

    -- Find H1 heading (the product title)
    if not h1_index and block.t == "Header" and block.level == 1 then
      h1_index = i
    end

    -- Find Description heading (can be H1 or H2 depending on DOCX structure)
    if not description_index and block.t == "Header" and (block.level == 1 or block.level == 2) then
      local text = pandoc.utils.stringify(block.content)
      if text == "Description" then
        description_index = i
      end
    end
  end

  -- If we found the first image and either the Description heading or H1
  if first_image and first_image_index then
    local target_position

    if description_index then
      -- Preferred: Position before Description heading
      -- Only remove the FIRST image (cover image) to avoid duplicates
      -- Other images were likely extracted from tables and should remain
      if first_image_index < description_index then
        table.remove(blocks, first_image_index)
        -- Adjust description_index since we removed one block before it
        description_index = description_index - 1
      end

      -- Set target to position before Description
      target_position = description_index

    elseif h1_index then
      -- Fallback: Position after H1 heading
      -- Only remove the FIRST image (cover image)
      if first_image_index <= h1_index then
        table.remove(blocks, first_image_index)
        -- Adjust h1_index since we removed one block before/at it
        h1_index = h1_index - 1
      end

      target_position = h1_index + 1
    else
      -- No positioning landmarks found, skip
      return pandoc.Pandoc(blocks, doc.meta)
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

    -- Insert the centered image at the target position
    table.insert(blocks, target_position, centered_image)
  end

  return pandoc.Pandoc(blocks, doc.meta)
end