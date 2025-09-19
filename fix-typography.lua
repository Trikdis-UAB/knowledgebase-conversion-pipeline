-- fix-typography.lua
function Str(el)
  el.text = el.text:gsub("`", "'")
  return el
end