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
local blocks = pandoc.List()
local description_titles = {
  ["description"] = true,
  ["descripción"] = true,
  ["descripcion"] = true,
  ["aprašymas"] = true,
  ["aprasymas"] = true
}

-- First pass: collect all blocks and find images, H1 title, and Description heading
function Pandoc(doc)
  first_image = nil
  first_image_index = nil
  h1_index = nil
  description_index = nil
  blocks = pandoc.List(doc.blocks)

  for i, block in ipairs(blocks) do
  end

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
      -- Try to get image src for debugging
      if block.t == "Para" and #block.content == 1 and block.content[1].t == "Image" then
        debug_log("Found image at index " .. i .. ": " .. block.content[1].src)
      else
        debug_log("Found image at index " .. i .. " (" .. block.t .. ")")
      end
    end

    -- Find H1 heading (the product title)
    if not h1_index and block.t == "Header" and block.level == 1 then
      h1_index = i
      debug_log("Found H1 at index " .. i .. ": " .. pandoc.utils.stringify(block.content))
    end

    -- Find Description heading (can be H1 or H2 depending on DOCX structure)
    if not description_index and block.t == "Header" and (block.level == 1 or block.level == 2) then
      local text = pandoc.utils.stringify(block.content)
      local normalized = text:lower()
      normalized = normalized:gsub('\194\160', ' ')
      normalized = normalized:gsub('^%s+', ''):gsub('%s+$', '')
      normalized = normalized:gsub('%s+', ' ')
      if description_titles[normalized] then
        description_index = i
        debug_log("Found Description heading at index " .. i .. ": '" .. normalized .. "'")
      end
    end
  end

  -- If we found the first image and either the Description heading or H1
  if first_image and first_image_index then
    debug_log("Using first image at index " .. first_image_index .. " (" .. first_image.t .. ")")
    if description_index then
      debug_log("Description index: " .. description_index)
    end
    if h1_index then
      debug_log("H1 index: " .. h1_index)
    end

    local centered_image
    if first_image.t == "Para" and #first_image.content == 1 and first_image.content[1].t == "Image" then
      local img = first_image.content[1]
      local alt = pandoc.utils.stringify(img.caption)
      local src = img.src
      centered_image = pandoc.RawBlock("html",
        '<div style="text-align: center;">\n  <img src="' .. src .. '" alt="' .. alt .. '" width="400">\n</div>')
    elseif first_image.t == "Para" and #first_image.content == 1 and first_image.content[1].t == "RawInline" then
      local img_html = first_image.content[1].text
      if not img_html:match('width=') then
        img_html = img_html:gsub('(<img[^>]*)', '%1 width="400"')
      end
      centered_image = pandoc.RawBlock("html",
        '<div style="text-align: center;">\n  ' .. img_html .. '\n</div>')
    elseif first_image.t == "CodeBlock" then
      local img_html = first_image.text:gsub("`", ""):gsub("{=html}", "")
      if not img_html:match('width=') then
        img_html = img_html:gsub('(<img[^>]*)', '%1 width="400"')
      end
      centered_image = pandoc.RawBlock("html",
        '<div style="text-align: center;">\n  ' .. img_html .. '\n</div>')
    elseif first_image.t == "RawBlock" and first_image.format == "html" then
      local img_html = first_image.text
      if not img_html:match('width=') then
        img_html = img_html:gsub('(<img[^>]*)', '%1 width="400"')
      end
      centered_image = pandoc.RawBlock("html",
        '<div style="text-align: center;">\n  ' .. img_html .. '\n</div>')
    else
      centered_image = pandoc.RawBlock("html",
        '<div style="text-align: center;">\n  <img src="./image1.png" alt="" width="400">\n</div>')
    end

    local inserted = false
    if description_index then
      if first_image_index < description_index then
        table.remove(blocks, first_image_index)
        description_index = description_index - 1
      end
      blocks:insert(description_index, centered_image)
      inserted = true
    elseif h1_index then
      if first_image_index <= h1_index then
        -- Image appears BEFORE the H1 — this is a genuine cover/product image.
        -- Remove it from its original position and re-insert as a centred div
        -- immediately after the H1.
        blocks:remove(first_image_index)
        h1_index = h1_index - 1
        blocks:insert(h1_index + 1, centered_image)
        inserted = true
      end
      -- If first_image_index > h1_index the image is CONTENT (e.g. a wiring diagram
      -- inside a numbered step).  Leave it untouched — no cover image for this doc.
    end

    if not inserted then
      -- No suitable cover image found; leave the document unchanged.
      -- (Do NOT fall back to replacing the image in-place as a centred div,
      -- because that would incorrectly centre content images like wiring diagrams.)
    end
  end

  doc.blocks = blocks
  return doc
end
