-- promote-strong-top.lua
local S = pandoc.utils.stringify

function Pandoc(doc)
  local out, seen_h2 = {}, false
  for _, b in ipairs(doc.blocks) do
    if b.t == 'Header' and b.level <= 2 then seen_h2 = true end
    if (not seen_h2) and b.t == 'Para' and #b.c == 1 and b.c[1].t == 'Strong' then
      local txt = S(b.c[1])
      if #txt >= 3 and not txt:match(':%s*$') then
        table.insert(out, pandoc.Header(2, b.c[1]))
      else
        table.insert(out, b)
      end
    else
      table.insert(out, b)
    end
  end
  return pandoc.Pandoc(out, doc.meta)
end