-- strip-cover.lua
function Pandoc(doc)
  local out, started = {}, false
  for _, b in ipairs(doc.blocks) do
    if not started then
      if b.t == "Header" then started = true; table.insert(out, b) end
    else
      table.insert(out, b)
    end
  end
  return pandoc.Pandoc(out, doc.meta)
end