-- promote-strong-top.lua
-- Extracts product name from cover page and creates proper H1 title
local S = pandoc.utils.stringify

function Pandoc(doc)
  local out = {}
  local seen_header = false
  local first_strong_found = false

  for i, b in ipairs(doc.blocks) do
    -- Track if we've seen any headers
    if b.t == 'Header' and b.level <= 2 then
      seen_header = true
    end

    -- Look for first bold paragraph (product name on cover)
    if not seen_header and not first_strong_found and b.t == 'Para' and #b.c == 1 and b.c[1].t == 'Strong' then
      local txt = S(b.c[1])

      -- Check if this matches product name pattern: "Cellular communicator [MODEL]"
      local model = txt:match("Cellular%s+communicator%s+(.+)$")
      if model then
        -- Found product name - create H1 title: "[MODEL] Cellular Communicator"
        local title = model .. " Cellular Communicator"
        table.insert(out, pandoc.Header(1, {pandoc.Str(title)}))
        first_strong_found = true
        -- Skip this block (don't add the original bold text)
      else
        -- Not a product name, treat as regular bold heading
        if #txt >= 3 and not txt:match(':%s*$') then
          table.insert(out, pandoc.Header(2, b.c[1]))
        else
          table.insert(out, b)
        end
      end
    else
      table.insert(out, b)
    end
  end

  return pandoc.Pandoc(out, doc.meta)
end