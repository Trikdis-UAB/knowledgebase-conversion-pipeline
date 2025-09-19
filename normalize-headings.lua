-- normalize-headings.lua
-- DOCX -> Markdown heading cleanup for Docs/BetterDocs
-- - Promote "1.1 Title" -> H3, "1.1.1 Title" -> H4, etc.
-- - Merge numeric-only headers (e.g., "1.2") with next short paragraph
-- - KEEP_TYPED_NUMBERS=true keeps "2. Wiring" in heading text

local KEEP_TYPED_NUMBERS = true
local stringify = pandoc.utils.stringify

local function is_numeric_only(s)
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  return s:match("^%d[%d%.]*%.?$") ~= nil
end

-- Only multi-level numbers like "1.1 ..." or "1.1.1 ..."
local function split_numbered_title(s)
  return s:match("^%s*([0-9]+%.[0-9%.]+)[%.)%-]?%s+(.*)$")
end

local function dotcount(s) return select(2, s:gsub("%.", "")) end

function Pandoc(doc)
  local blocks, out, i = doc.blocks, {}, 1

  while i <= #blocks do
    local b = blocks[i]

    -- 1) Fix numeric-only Headers by pulling next short paragraph as title
    if b.t == "Header" then
      local txt = stringify(b.content or {})
      if is_numeric_only(txt) then
        local j = i + 1
        while j <= #blocks do
          local nb = blocks[j]
          if nb.t == "Para" or nb.t == "Plain" then
            local nt = stringify(nb):gsub("^%s+",""):gsub("%s+$","")
            if nt ~= "" and #nt <= 120 and not nt:match("[%.!?]$") then
              b.content = nb.content
              table.insert(out, b)
              i = j + 1
              goto continue
            else
              break
            end
          elseif nb.t == "Header" then
            break
          end
          j = j + 1
        end
      else
        if not KEEP_TYPED_NUMBERS then
          local num, rest = split_numbered_title(txt)
          if num and rest and rest ~= "" then
            b.content = pandoc.Inlines(pandoc.Str(rest))
          end
        end
        table.insert(out, b)
        i = i + 1
        goto continue
      end
    end

    -- 2) Promote numbered paragraphs/lists to headers (H3/H4/H5)
    if b.t == "Para" or b.t == "Plain" then
      local txt = stringify(b):gsub("^%s+",""):gsub("%s+$","")
      local num, rest = split_numbered_title(txt)
      if num and rest and rest ~= "" then
        local dots = dotcount(num)                   -- 1.1 -> 1 dot => H3; 1.1.1 -> 2 dots => H4...
        local level = 3 + math.max(0, math.min(3, dots - 1)) -- clamp to H3..H6
        local content = KEEP_TYPED_NUMBERS
            and pandoc.Inlines(pandoc.Str(num .. " " .. rest))
            or  pandoc.Inlines(pandoc.Str(rest))
        table.insert(out, pandoc.Header(level, content))
        i = i + 1
        goto continue
      end
    end

    -- passthrough
    table.insert(out, b)
    i = i + 1
    ::continue::
  end

  return pandoc.Pandoc(out, doc.meta)
end