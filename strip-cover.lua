-- strip-cover.lua
-- Removes cover page content but preserves product name and cover image
-- Handles multiple product name formats:
-- 1. "Cellular communicator [MODEL]" (GT/GT+)
-- 2. "Cellular/Ethernet communicator [MODEL]" (GET)
-- 3. "Control panel [MODEL]" (SP3)
-- 4. Other communicator/controller/panel types

local S = pandoc.utils.stringify

function Pandoc(doc)
  local out = {}
  local started = false
  local product_name_saved = false
  local cover_image_saved = false

  for _, b in ipairs(doc.blocks) do
    if not started then
      -- Preserve first image (cover photo) for move-first-image-to-description.lua
      if not cover_image_saved and b.t == "Para" and #b.c == 1 and b.c[1].t == "Image" then
        table.insert(out, b)
        cover_image_saved = true
      -- Preserve first bold paragraph (product name) for promote-strong-top.lua
      elseif not product_name_saved and b.t == "Para" and #b.c == 1 and b.c[1].t == "Strong" then
        local txt = S(b.c[1])

        -- Check for various product type patterns
        local lower_txt = txt:lower()
        if lower_txt:match("communicator") or lower_txt:match("comunicador") or lower_txt:match("komunikatorius")
            or lower_txt:match("controller") or lower_txt:match("panel") then
          table.insert(out, b)
          product_name_saved = true
        end
      elseif b.t == "Header" then
        started = true
        table.insert(out, b)
      end
    else
      table.insert(out, b)
    end
  end

  return pandoc.Pandoc(out, doc.meta)
end
