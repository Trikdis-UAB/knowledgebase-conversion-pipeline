-- promote-strong-top.lua
-- Extracts product name from cover page and creates proper H1 title
-- Handles multiple cover formats:
-- 1. "Cellular communicator [MODEL]" (GT/GT+ style)
-- 2. "Cellular/Ethernet communicator [MODEL]" (GET style)
-- 3. H2 at document start (SP3 style: "## **Security control panel...**")
-- 4. Other bold text patterns

local S = pandoc.utils.stringify

function Pandoc(doc)
  local out = {}
  local seen_header = false
  local first_strong_found = false
  local processed_first_h2 = false

  for i, b in ipairs(doc.blocks) do
    -- Track if we've seen any headers
    if b.t == 'Header' and b.level <= 2 then
      -- SP3-style: If this is the FIRST H2 we encounter, convert to H1 and remove bold
      if not seen_header and b.level == 2 then
        -- This is the first H2 - promote to H1
        b.level = 1

        -- Remove bold formatting (Strong elements) from heading content
        local new_content = {}
        for _, inline in ipairs(b.content) do
          if inline.t == 'Strong' then
            -- Unwrap Strong - add its content directly
            for _, inner in ipairs(inline.content) do
              table.insert(new_content, inner)
            end
          else
            table.insert(new_content, inline)
          end
        end
        b.content = new_content

        table.insert(out, b)
        seen_header = true
        first_strong_found = true  -- Don't process bold paragraphs
        goto continue
      end

      seen_header = true
    end

    -- Look for first bold paragraph (product name on cover) - GT/GT+/GET style
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

      -- Pattern 5: "GSM gate controller [MODEL]" (GATOR Cellular style)
      if not model then
        model = txt:match("^GSM%s+gate%s+controller%s+(.+)$")
        if model then
          product_type = "Cellular Gate Controller"
        end
      end

      -- Pattern 6: "WiFi gate controller [MODEL]" (GATOR WiFi style)
      if not model then
        model = txt:match("^WiFi%s+gate%s+controller%s+(.+)$")
        if model then
          product_type = "WiFi Gate Controller"
        end
      end

      -- Pattern 7: "Gate controller [MODEL]" (generic fallback for gate controllers)
      if not model then
        model = txt:match("^Gate%s+controller%s+(.+)$")
        if model then
          product_type = "Gate Controller"
        end
      end

      -- Pattern 8: "Comunicador [MODEL]" (Spanish manuals)
      if not model then
        model = txt:match("^Comunicador%s+(.+)$")
        if model then
          product_type = "Comunicador"
        end
      end

      -- Pattern 9: "[MODEL] Comunicador" (Spanish alternate order)
      if not model then
        local lead, tail = txt:match("^([A-Z0-9%+%-]+)%s+Comunicador%s*(.*)$")
        if lead then
          model = lead
          if tail ~= "" then
            product_type = "Comunicador " .. tail
          else
            product_type = "Comunicador"
          end
        end
      end

      -- Pattern 10: "GSM komunikatorius [MODEL]" (Lithuanian manuals)
      if not model then
        model = txt:match("^GSM%s+komunikatorius%s+(.+)$")
        if model then
          product_type = "GSM komunikatorius"
        end
      end

      -- Pattern 11: "Komunikatorius [MODEL]" (generic Lithuanian)
      if not model then
        model = txt:match("^Komunikatorius%s+(.+)$")
        if model then
          product_type = "Komunikatorius"
        end
      end

      if model then
        -- Found product name - create H1 title: "[MODEL] Product Type"
        model = model:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")  -- Trim whitespace
        local title = model .. " " .. product_type
        table.insert(out, pandoc.Header(1, {pandoc.Str(title)}))
        first_strong_found = true
        goto continue
      else
        -- Not a recognized product name pattern - promote to H1 using the original text
        local header_content = {}
        if b.c[1] and b.c[1].content then
          for _, inline in ipairs(b.c[1].content) do
            if inline.t ~= 'LineBreak' then
              table.insert(header_content, inline)
            end
          end
        end
        if #header_content == 0 then
          header_content = {pandoc.Str(txt)}
        end
        table.insert(out, pandoc.Header(1, header_content))
        first_strong_found = true
        goto continue
      end
    else
      table.insert(out, b)
    end

    ::continue::
  end

  return pandoc.Pandoc(out, doc.meta)
end
