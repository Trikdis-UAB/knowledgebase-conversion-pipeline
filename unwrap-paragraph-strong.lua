local MIN_LENGTH = 80

local function unwrap_all_strong(p)
  local total_len = 0
  local flattened = pandoc.List()

  for _, inline in ipairs(p.content) do
    if inline.t == 'Strong' then
      local text = pandoc.utils.stringify(inline)
      total_len = total_len + #text
      for _, inner in ipairs(inline.content) do
        flattened:insert(inner)
      end
    elseif inline.t == 'Space' or inline.t == 'SoftBreak' then
      flattened:insert(inline)
    else
      return nil
    end
  end

  if total_len < MIN_LENGTH then
    return nil
  end

  return flattened
end

function Para(p)
  if not p.content then
    return nil
  end

  local flattened = unwrap_all_strong(p)
  if not flattened then
    return nil
  end

  p.content = flattened
  return p
end

return {
  { Para = Para }
}
