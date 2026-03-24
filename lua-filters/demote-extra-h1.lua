-- demote-extra-h1.lua
-- Ensures only the FIRST H1 (product title) remains as H1.
-- All subsequent H1 headings are demoted to H2.
--
-- This is more robust than a keyword whitelist because it works for any
-- product type (communicators, gate controllers, expanders, keypads, etc.)
-- without needing to enumerate every possible product category.
--
-- This runs after promote-strong-top.lua creates the product title.

function Pandoc(doc)
  local blocks = doc.blocks
  local seen_first_h1 = false

  for i, block in ipairs(blocks) do
    if block.t == "Header" and block.level == 1 then
      if not seen_first_h1 then
        -- Keep the very first H1 — that is the product title
        seen_first_h1 = true
      else
        -- Demote any subsequent H1 to H2
        block.level = 2
        blocks[i] = block
      end
    end
  end

  return pandoc.Pandoc(blocks, doc.meta)
end
