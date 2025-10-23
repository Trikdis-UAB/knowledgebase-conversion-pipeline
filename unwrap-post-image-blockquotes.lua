-- unwrap-post-image-blockquotes.lua
-- Unwraps blockquotes that appear immediately after images
-- This fixes the issue where text continuation after an image is wrapped in blockquotes

function Pandoc(doc)
  local blocks = {}
  local previous_had_image = false

  for i, block in ipairs(doc.blocks) do
    -- Check if this block contains an image (Para, Table, or any block type)
    local has_image = false
    pandoc.walk_block(block, {
      Image = function(img)
        has_image = true
      end
    })

    if block.t == "BlockQuote" and previous_had_image then
      -- Unwrap the blockquote - add its contents directly
      for _, inner_block in ipairs(block.content) do
        table.insert(blocks, inner_block)
      end
      previous_had_image = false
    else
      table.insert(blocks, block)
      previous_had_image = has_image
    end
  end

  return pandoc.Pandoc(blocks, doc.meta)
end
