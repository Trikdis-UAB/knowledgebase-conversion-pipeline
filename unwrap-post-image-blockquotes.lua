-- unwrap-post-image-blockquotes.lua
-- Unwraps blockquotes that appear immediately after images
-- This fixes the issue where text continuation after an image is wrapped in blockquotes

function Pandoc(doc)
  local blocks = {}
  local previous_was_para_with_image = false

  for i, block in ipairs(doc.blocks) do
    if block.t == "Para" then
      -- Check if this paragraph contains an image
      local has_image = false
      pandoc.walk_block(block, {
        Image = function(img)
          has_image = true
        end
      })

      table.insert(blocks, block)
      previous_was_para_with_image = has_image

    elseif block.t == "BlockQuote" and previous_was_para_with_image then
      -- Unwrap the blockquote - add its contents directly
      for _, inner_block in ipairs(block.content) do
        table.insert(blocks, inner_block)
      end
      previous_was_para_with_image = false

    else
      table.insert(blocks, block)
      previous_was_para_with_image = false
    end
  end

  return pandoc.Pandoc(blocks, doc.meta)
end
