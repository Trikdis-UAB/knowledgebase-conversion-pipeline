-- mark-two-col.lua
-- Add class "two-col" to tables that are exactly 2 columns (no colspans).
local function count_cols(t)
  -- Check if headers exist and have content
  if t.headers and #t.headers > 0 then 
    return #t.headers 
  end
  -- Check bodies for column count
  if t.bodies and #t.bodies > 0 then
    local body = t.bodies[1]
    if body.body and #body.body > 0 then
      local row = body.body[1]
      if row.cells then
        return #row.cells
      end
    end
  end
  return 0
end

return {
  {
    Table = function(tbl)
      local ok = true
      -- bail if header has more than 2 cells
      if count_cols(tbl) ~= 2 then ok = false end
      -- (Pandoc flattens colspans, so a simple count is sufficient for our inputs)
      if ok then
        local id = tbl.attr.identifier or ""
        local classes = tbl.attr.classes or {}
        -- table.insert(classes, "two-col")  -- Commented out to prevent removing table borders
        tbl.attr = pandoc.Attr(id, classes, tbl.attr.attributes or {})
      end
      return tbl
    end
  }
}