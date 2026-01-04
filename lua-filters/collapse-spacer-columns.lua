local List = require 'pandoc.List'

local SPACER_THRESHOLD = 0.05 -- relative width

local function is_spacer_column(spec)
  if type(spec) ~= 'table' then
    return false
  end
  local col = spec[2]
  if type(col) ~= 'table' or col.t ~= 'ColWidth' then
    return false
  end
  local width = col.c or 0
  return width >= 0 and width < SPACER_THRESHOLD
end

local function drop_middle_column(tbl)
  if not tbl.colspecs or #tbl.colspecs ~= 3 then
    return false
  end
  if not is_spacer_column(tbl.colspecs[2]) then
    return false
  end

  local old_specs = tbl.colspecs
  tbl.colspecs = List({ old_specs[1], old_specs[3] })

  local function rewrite_rows(rows)
    if not rows then
      return
    end
    for _, row in ipairs(rows) do
      if row.cells and #row.cells == 3 then
        row.cells = List({ row.cells[1], row.cells[3] })
      end
    end
  end

  rewrite_rows(tbl.head and tbl.head.rows)
  for _, body in ipairs(tbl.bodies or {}) do
    rewrite_rows(body.body)
  end
  rewrite_rows(tbl.foot and tbl.foot.rows)

  return true
end

return {
  {
    Table = function(tbl)
      if drop_middle_column(tbl) then
        return tbl
      end
      return nil
    end
  }
}
