-- promote-strong-top.lua
-- Extracts product name from cover page and creates proper H1 title
-- Handles multiple cover formats:
-- 1. "Cellular communicator [MODEL]" (GT/GT+ style)
-- 2. "Cellular/Ethernet communicator [MODEL]" (GET style)
-- 3. Other bold text patterns

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
      local model = nil
      local product_type = "Cellular Communicator"  -- Default

      -- Pattern 1: "Cellular communicator [MODEL]" (GT/GT+ style)
      model = txt:match("^Cellular%s+communicator%s+(.+)$")
      if model then
        product_type = "Cellular Communicator"
      end

      -- Pattern 2: "Cellular/Ethernet communicator [MODEL]" (GET style)
      if not model then
        model = txt:match("^Cellular/Ethernet%s+communicator%s+(.+)$")
        if model then
          product_type = "Cellular Communicator"  -- Simplify to standard name
        end
      end

      -- Pattern 3: "Ethernet communicator [MODEL]"
      if not model then
        model = txt:match("^Ethernet%s+communicator%s+(.+)$")
        if model then
          product_type = "Ethernet Communicator"
        end
      end

      -- Pattern 4: Reverse order "[MODEL] communicator" (some products)
      if not model then
        model = txt:match("^([A-Z][A-Z0-9%+%-]+)%s+[Cc]ellular%s+[Cc]ommunicator$")
        if model then
          product_type = "Cellular Communicator"
        end
      end

      if model then
        -- Found product name - create H1 title: "[MODEL] Cellular Communicator"
        model = model:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")  -- Trim whitespace
        local title = model .. " " .. product_type
        table.insert(out, pandoc.Header(1, {pandoc.Str(title)}))
        first_strong_found = true
        -- Skip this block (don't add the original bold text)
      else
        -- Not a recognized product name pattern
        -- Treat as regular bold heading if it's substantive
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