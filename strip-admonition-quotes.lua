-- strip-admonition-quotes.lua
-- Remove residual '>' markers inside MkDocs admonition blocks

local function is_str(inline, value)
  if inline.t ~= 'Str' then
    return false
  end
  local text = inline.text or inline.c
  return text == value
end

function Para(p)
  if not p.content then
    return nil
  end

  local new_inlines = pandoc.List()
  local changed = false
  local previous = nil

  for _, inline in ipairs(p.content) do
    if is_str(inline, '>') and previous and previous.t == 'SoftBreak' then
      changed = true
    else
      new_inlines:insert(inline)
    end
    previous = inline
  end

  if changed then
    p.content = new_inlines
    return p
  end

  return nil
end

return {
  { Para = Para }
}
