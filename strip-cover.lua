-- strip-cover.lua
-- Removes cover page content but preserves product name for title generation
local S = pandoc.utils.stringify

function Pandoc(doc)
  local out = {}
  local started = false
  local product_name_saved = false

  for _, b in ipairs(doc.blocks) do
    if not started then
      -- Preserve first bold paragraph (product name) for promote-strong-top.lua
      if not product_name_saved and b.t == "Para" and #b.c == 1 and b.c[1].t == "Strong" then
        local txt = S(b.c[1])
        if txt:match("Cellular%s+communicator") then
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