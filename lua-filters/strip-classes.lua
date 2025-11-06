-- strip-classes.lua
-- Remove classes/attributes from Span/Div/Header to clean up Markdown like `{.underline}`
local function clear_attr(attr)
  return pandoc.Attr(attr.identifier, {}, {}) -- keep id if present; drop classes/attrs
end

function Span(el)
  el.attr = clear_attr(el.attr)
  return el
end

function Div(el)
  el.attr = clear_attr(el.attr)
  return el
end

function Header(el)
  el.attr = clear_attr(el.attr)
  return el
end