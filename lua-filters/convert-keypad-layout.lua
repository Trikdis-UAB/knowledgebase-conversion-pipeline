local List = require 'pandoc.List'
local utils = require 'pandoc.utils'

local TITLE_KEYWORDS = {
  'Keypad',
  'Klaviatūra',
  'Teclado',
  'Клавиатура'
}

local function trim(text)
  return text:gsub('^%s+', ''):gsub('%s+$', '')
end

local function blocks_to_string(blocks)
  local ok, text = pcall(utils.stringify, pandoc.Pandoc(blocks, pandoc.Meta{}))
  if not ok then
    return ''
  end
  return trim(text)
end

local function contains_keyword(text)
  local lower = text:lower()
  for _, kw in ipairs(TITLE_KEYWORDS) do
    if lower:find(kw:lower(), 1, true) then
      return true
    end
  end
  return false
end

local function has_spacer_column(tbl)
  if not tbl.colspecs or #tbl.colspecs ~= 3 then
    return false
  end
  local spec = tbl.colspecs[2]
  if type(spec) == 'table' then
    local col = spec[2]
    if type(col) == 'table' and col.t == 'ColWidth' then
      local width = col.c or 0
      return width >= 0 and width < 0.08
    end
  end
  -- fallback: treat middle column with mostly empty cells as spacer
  local function column_empty(rows)
    if not rows then
      return true
    end
    for _, row in ipairs(rows) do
      if row.cells and #row.cells == 3 then
        local cell = row.cells[2]
        if cell then
          local contents = cell.content or cell.contents
          if contents and #contents > 0 then
            local text = trim(utils.stringify(pandoc.Pandoc(contents, pandoc.Meta{})))
            if text ~= '' then
              return false
            end
          end
        end
      end
    end
    return true
  end
  if not column_empty(tbl.head and tbl.head.rows) then
    return false
  end
  for _, body in ipairs(tbl.bodies or {}) do
    if not column_empty(body.body) then
      return false
    end
  end
  return true
end

local function is_keypad_table(tbl)
  local col_count = tbl.colspecs and #tbl.colspecs or 0
  if col_count < 2 or col_count > 3 then
    return false
  end
  local head = tbl.head and tbl.head.rows
  if not head or #head == 0 then
    return false
  end
  local first_row = head[1]
  if not first_row.cells or #first_row.cells == 0 then
    return false
  end
  local first_cell = first_row.cells[1]
  if not first_cell then
    return false
  end
  local text = blocks_to_string(first_cell.content or first_cell.contents or List())
  if text == '' then
    return has_spacer_column(tbl)
  end
  if contains_keyword(text) then
    return true
  end
  return has_spacer_column(tbl)
end

return {
  {
    Table = function(tbl)
      if not is_keypad_table(tbl) then
        return nil
      end
      local attr = tbl.attr or pandoc.Attr()
      attr.attributes = attr.attributes or {}
      attr.classes = attr.classes or {}
      local table_type = has_spacer_column(tbl) and 'keypad-three-col' or 'keypad-two-col'
      attr.attributes['data-keypad-table'] = table_type
      tbl.attr = attr
      local json = pandoc.write(pandoc.Pandoc({tbl}, pandoc.Meta{}), 'json')
      return {
        pandoc.RawBlock('markdown', '```keypad-table ' .. table_type),
        pandoc.RawBlock('markdown', json),
        pandoc.RawBlock('markdown', '```')
      }
    end
  }
}
