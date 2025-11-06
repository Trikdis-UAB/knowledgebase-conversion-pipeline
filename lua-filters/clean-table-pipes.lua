-- clean-table-pipes.lua
-- Inside table cells, remove literal '|' characters from text.
local function strip_pipes_inline(el)
  if el.t == "Str" and el.text:find("|", 1, true) then
    el.text = el.text:gsub("|", "")
  end
  return el
end

return {
  {
    Table = function(tbl)
      -- Walk the table and strip pipes from any inline strings
      return pandoc.walk_block(tbl, { Str = strip_pipes_inline })
    end
  }
}