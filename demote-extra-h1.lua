-- demote-extra-h1.lua
-- Ensures only the first H1 (product title) remains
-- Demotes all subsequent H1 headings to H2
-- This runs after promote-strong-top.lua creates the product title

function Pandoc(doc)
  local blocks = doc.blocks

  -- Product title patterns to keep as H1
  local product_patterns = {
    "Alarm Panel",
    "Control Panel",
    "control panel",  -- Matches "Security control panel"
    "Cellular Communicator",
    "Ethernet Communicator",
    "Gate Controller",
    "Communicator",
    "Comunicador",
    "komunikatorius",
    "Komunikatorius"
  }

  -- Helper: Check if text matches any product pattern
  local function is_product_title(text)
    for _, pattern in ipairs(product_patterns) do
      if text:match(pattern) then
        return true
      end
    end
    return false
  end

  for i, block in ipairs(blocks) do
    -- If this is an H1 heading
    if block.t == "Header" and block.level == 1 then
      local text = pandoc.utils.stringify(block.content)

      if is_product_title(text) then
        -- Keep product title as H1
        -- (Product titles contain: Alarm Panel, Control Panel, Cellular Communicator, Gate Controller)
      else
        -- Demote non-product H1s to H2
        block.level = 2
      end
    end
  end

  return pandoc.Pandoc(blocks, doc.meta)
end
