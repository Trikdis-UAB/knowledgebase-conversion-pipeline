-- reduce-excess-strong.lua
-- Remove bold formatting for excessively long Strong spans (likely whole paragraphs)

local MAX_STRONG_CHARS = 120

function Strong(el)
  local text = pandoc.utils.stringify(el)
  if #text >= MAX_STRONG_CHARS then
    return el.content
  end
  return nil
end

return {
  { Strong = Strong }
}
