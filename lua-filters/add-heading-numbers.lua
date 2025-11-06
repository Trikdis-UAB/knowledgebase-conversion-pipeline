-- add-heading-numbers.lua
-- Prefixes H2/H3 headings with automatic numbering (1., 1.1, etc.)
-- Resets counters per document and skips headings that already contain numeric prefixes.

local stringify = pandoc.utils.stringify

local counters = {
  [2] = 0,
  [3] = 0,
}

local function first_str(content)
  if not content then
    return nil
  end
  for _, inline in ipairs(content) do
    if inline.t == 'Str' then
      return inline.text or inline.c
    elseif inline.t ~= 'Space' and inline.t ~= 'SoftBreak' then
      break
    end
  end
  return nil
end

local function already_numbered(content)
  local first = first_str(content)
  if not first then
    return false
  end
  if first:match('^%d+[%.,]%d') then
    return true
  end
  if first:match('^%d+[%.,]?%s') then
    return true
  end
  return false
end

local function prefix_label(label, content)
  local inlines = pandoc.List()
  inlines:insert(pandoc.Str(label))
  inlines:insert(pandoc.Space())
  if content then
    for _, inline in ipairs(content) do
      inlines:insert(inline)
    end
  end
  return pandoc.Inlines(inlines)
end

function Header(header)
  if header.level == 2 then
    counters[2] = counters[2] + 1
    counters[3] = 0
    if not already_numbered(header.content) then
      local label = string.format('%d.', counters[2])
      header.content = prefix_label(label, header.content)
    end
  elseif header.level == 3 then
    if counters[2] > 0 then
      counters[3] = counters[3] + 1
      if not already_numbered(header.content) then
        local label = string.format('%d.%d', counters[2], counters[3])
        header.content = prefix_label(label, header.content)
      end
    end
  else
    -- For other levels (H1/H4+), keep counters but do not modify numbering
  end
  return header
end

function Pandoc(doc)
  -- Reset counters per document
  counters[2] = 0
  counters[3] = 0
  return doc:walk{ Header = Header }
end

return {
  { Pandoc = Pandoc }
}
