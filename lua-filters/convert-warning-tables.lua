local pandoc = require 'pandoc'

local function cell_has_icon(cell)
  if #cell.contents ~= 1 then
    return false
  end
  local block = cell.contents[1]
  if block.t ~= 'Plain' and block.t ~= 'Para' then
    return false
  end
  for _, inline in ipairs(block.c) do
    if inline.t == 'Image' then
      return true
    end
  end
  return false
end

local function serialize_blocks(blocks)
  local doc = pandoc.Pandoc(blocks)
  local md = pandoc.write(doc, 'markdown')
  md = md:gsub('\r', '')
  md = md:gsub('%s+$', '')
  return md
end

local function indent_markdown(md)
  md = md:gsub('^\n+', '')
  md = md:gsub('%s+$', '')
  local indented = md:gsub('\n', '\n    ')
  return '    ' .. indented
end

function Table(tbl)
  if #tbl.bodies ~= 1 then
    return nil
  end
  local body = tbl.bodies[1]
  if #body.body ~= 1 then
    return nil
  end
  local row = body.body[1]
  if #row.cells ~= 2 then
    return nil
  end

  local icon_cell = row.cells[1]
  local content_cell = row.cells[2]

  if not cell_has_icon(icon_cell) then
    return nil
  end

  local content_blocks = content_cell.contents
  if not content_blocks or #content_blocks == 0 then
    return nil
  end

  local md = serialize_blocks(content_blocks)
  if md == '' then
    return nil
  end

  local admonition_md = '!!! warning\n' .. indent_markdown(md) .. '\n'
  io.stderr:write('[convert-warning-tables] converted warning table\n')
  return { pandoc.RawBlock('markdown', admonition_md) }
end

return {
  { Table = Table }
}
