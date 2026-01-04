local List = require 'pandoc.List'
local utils = require 'pandoc.utils'

local function is_blank_block(block)
  if block.t == 'Para' or block.t == 'Plain' then
    local text = utils.stringify(block)
    return text:match('^%s*$') ~= nil
  end
  return block.t == 'Null'
end

local function cell_has_complex_content(cell)
  local long_para = false
  local para_count = 0
  for _, block in ipairs(cell.contents) do
    if block.t == 'BulletList'
      or block.t == 'OrderedList'
      or block.t == 'DefinitionList'
      or block.t == 'Table'
      or block.t == 'Div'
      or block.t == 'BlockQuote'
      or block.t == 'Header'
    then
      return true
    elseif block.t == 'Para' or block.t == 'Plain' then
      para_count = para_count + 1
      local text = utils.stringify(block)
      if #text > 120 then
        long_para = true
      end
    end
  end
  return long_para or para_count > 1
end

local function get_column_count(tbl)
  if tbl.colspecs and #tbl.colspecs > 0 then
    return #tbl.colspecs
  end

  local function from_rows(rows)
    if not rows then
      return 0
    end
    for _, row in ipairs(rows) do
      if row.cells and #row.cells > 0 then
        return #row.cells
      end
    end
    return 0
  end

  local count = from_rows(tbl.head and tbl.head.rows)
  if count > 0 then
    return count
  end

  if tbl.bodies then
    for _, body in ipairs(tbl.bodies) do
      count = from_rows(body.head and body.head.rows)
      if count > 0 then
        return count
      end
      count = from_rows(body.body)
      if count > 0 then
        return count
      end
    end
  end

  if tbl.foot then
    count = from_rows(tbl.foot.rows)
    if count > 0 then
      return count
    end
  end

  return 0
end

local function cell_has_content(cell)
  if not cell or not cell.contents then
    return false
  end
  for _, block in ipairs(cell.contents) do
    if not is_blank_block(block) then
      return true
    end
  end
  return false
end

local function cell_text_length(cell)
  if not cell or not cell.contents then
    return 0
  end
  local total = 0
  for _, block in ipairs(cell.contents) do
    if block.t == 'Para' or block.t == 'Plain' or block.t == 'Header' then
      total = total + #utils.stringify(block)
    end
  end
  return total
end

local function is_heading_candidate(block)
  if not block then
    return false
  end
  if block.t ~= 'Para' and block.t ~= 'Plain' and block.t ~= 'Header' then
    return false
  end
  local text = utils.stringify(block)
  if text == '' then
    return false
  end
  if #text > 80 then
    return false
  end
  if text:match('[%.,:;!?]') then
    return false
  end
  return true
end

local function collect_column_info(tbl, col_count)
  local info = {}
  for col = 1, col_count do
    info[col] = {
      text = 0,
      cells = 0,
      long_cells = 0,
      heading = 0
    }
  end

  local function inspect_cell(cell, col)
    if not cell or not cell.contents then
      return
    end
    local length = cell_text_length(cell)
    if length <= 0 then
      return
    end
    local data = info[col]
    data.text = data.text + length
    data.cells = data.cells + 1
    if length >= 80 then
      data.long_cells = data.long_cells + 1
    end
    local first = cell.contents[1]
    if first and is_heading_candidate(first) then
      data.heading = data.heading + 1
    end
  end

  local function process_rows(rows)
    if not rows then
      return
    end
    for _, row in ipairs(rows) do
      if row.cells then
        for col = 1, col_count do
          inspect_cell(row.cells[col], col)
        end
      end
    end
  end

  process_rows(tbl.head and tbl.head.rows)
  if tbl.bodies then
    for _, body in ipairs(tbl.bodies) do
      process_rows(body.head and body.head.rows)
      process_rows(body.body)
    end
  end
  process_rows(tbl.foot and tbl.foot.rows)

  return info
end

local function collect_stats(tbl, col_count)
  local stats = {
    total_cells = 0,
    complex_cells = 0,
    list_cells = 0,
    has_full_span = false,
    row_count = 0,
    long_cells = 0
  }

  local function inspect_cell(cell)
    if not cell then
      return
    end
    local span = cell.col_span or 1
    if span >= col_count then
      stats.has_full_span = true
    end
    if cell_has_content(cell) then
      stats.total_cells = stats.total_cells + 1
      if cell_has_complex_content(cell) then
        stats.complex_cells = stats.complex_cells + 1
      end
      if cell_text_length(cell) > 80 then
        stats.long_cells = stats.long_cells + 1
      end
      for _, block in ipairs(cell.contents) do
        if block.t == 'OrderedList' or block.t == 'BulletList' then
          stats.list_cells = stats.list_cells + 1
          break
        end
      end
    end
  end

  local function inspect_rows(rows)
    if not rows then
      return
    end
    for _, row in ipairs(rows) do
      stats.row_count = stats.row_count + 1
      if row.cells then
        for _, cell in ipairs(row.cells) do
          inspect_cell(cell)
        end
      end
    end
  end

  inspect_rows(tbl.head and tbl.head.rows)
  if tbl.bodies then
    for _, body in ipairs(tbl.bodies) do
      inspect_rows(body.head and body.head.rows)
      inspect_rows(body.body)
    end
  end
  inspect_rows(tbl.foot and tbl.foot.rows)

  return stats
end

local function determine_column_mode(tbl, col_count)
  if col_count < 2 then
    return nil
  end

  local stats = collect_stats(tbl, col_count)
  if stats.row_count < 3 then
    return nil
  end

  local info = collect_column_info(tbl, col_count)
  local candidates = {}
  local total_text = 0
  for col = 1, col_count do
    local data = info[col] or {}
    local text = data.text or 0
    total_text = total_text + text
    table.insert(candidates, {
      index = col,
      text = text,
      cells = data.cells or 0,
      heading = data.heading or 0,
      avg = (data.cells or 0) > 0 and (text / data.cells) or 0
    })
  end

  table.sort(candidates, function(a, b)
    return a.text > b.text
  end)

  local selected = {}
  for _, candidate in ipairs(candidates) do
    if candidate.text >= 120 and candidate.avg >= 40 and candidate.cells >= 2 and candidate.heading > 0 then
      table.insert(selected, candidate.index)
    end
    if #selected == 2 then
      break
    end
  end

  if #selected < 2 then
    return nil
  end

  table.sort(selected)

  local top_text = 0
  for _, col in ipairs(selected) do
    local data = info[col] or {}
    top_text = top_text + (data.text or 0)
  end

  if total_text > 0 and (top_text / total_text) < 0.75 then
    return nil
  end

  return { columns = selected }
end

local function should_flatten(tbl)
  local col_count = get_column_count(tbl)
  if col_count == 0 or col_count > 4 then
    return false
  end

  local stats = collect_stats(tbl, col_count)
  if stats.total_cells == 0 then
    return false
  end

  local complex_ratio = stats.complex_cells / stats.total_cells
  local list_ratio = stats.list_cells / stats.total_cells
  local long_ratio = stats.long_cells / stats.total_cells

  if col_count == 1 then
    return stats.row_count >= 3
  end

  if stats.has_full_span and stats.complex_cells >= 2 then
    return true
  end

  if col_count <= 2 and long_ratio >= 0.4 and stats.row_count >= 3 then
    return true
  end

  if list_ratio >= 0.3 and stats.row_count >= 3 then
    return true
  end

  if complex_ratio >= 0.5 and stats.row_count >= 3 then
    return true
  end

  return false
end

local function flatten_table(tbl)
  local blocks = List()
  local active_lists = {}
  local col_count = get_column_count(tbl)
  if col_count == 0 then
    col_count = 1
  end

  local column_mode = determine_column_mode(tbl, col_count)
  local column_mode_enabled = column_mode ~= nil
  local column_buffers = {}
  local selected_lookup = {}
  if column_mode_enabled then
    for _, col in ipairs(column_mode.columns) do
      column_buffers[col] = List()
      selected_lookup[col] = true
    end
  end

  local function is_selected(col)
    if not column_mode_enabled then
      return true
    end
    return selected_lookup[col] == true
  end

  local function get_target(col)
    if column_mode_enabled and selected_lookup[col] then
      return column_buffers[col]
    end
    return blocks
  end

  local function flush_column(col)
    if column_mode_enabled and not selected_lookup[col] then
      active_lists[col] = nil
      return
    end
    local state = active_lists[col]
    if state and state.items and #state.items > 0 then
      local attrs = pandoc.ListAttributes(state.start or 1)
      get_target(col):insert(pandoc.OrderedList(state.items, attrs))
    end
    active_lists[col] = nil
  end

  local function flush_all_columns()
    if column_mode_enabled then
      for _, col in ipairs(column_mode.columns) do
        flush_column(col)
      end
    else
      for col = 1, col_count do
        flush_column(col)
      end
    end
  end

  local function append_list(col, block)
    local attr = block.c and block.c[1] or nil
    local start = 1
    if type(block.start) == 'number' then
      start = block.start
    elseif attr then
      if type(attr.start) == 'number' then
        start = attr.start
      elseif type(attr[1]) == 'number' then
        start = attr[1]
      end
    end
    local items = (block.c and block.c[2]) or List()
    local state = active_lists[col]
    if not state then
      state = { start = start, items = List() }
      active_lists[col] = state
    end
    for _, item in ipairs(items) do
      state.items:insert(item)
    end
  end

  local function append_block(col, block)
    if not is_blank_block(block) then
      get_target(col):insert(block)
    end
  end

  local function append_direct(block)
    if not is_blank_block(block) then
      blocks:insert(block)
    end
  end

  local function maybe_promote_heading(block, col)
    if is_heading_candidate(block) then
      local level = column_mode_enabled and 3 or (col == 1 and 3 or 4)
      return pandoc.Header(level, block.content or block.c)
    end
    return block
  end

  local function append_cell(cell, col)
    if not cell or not cell.contents then
      flush_column(col)
      return
    end

    if not is_selected(col) then
      for _, block in ipairs(cell.contents) do
        append_direct(block)
      end
      return
    end

    local first_block = true
    for _, block in ipairs(cell.contents) do
      if block.t == 'OrderedList' then
        append_list(col, block)
        first_block = false
      else
        flush_column(col)
        if first_block then
          block = maybe_promote_heading(block, col)
          first_block = false
        end
        append_block(col, block)
      end
    end
  end

  local function process_row(cells)
    if not cells then
      return
    end
    for col = 1, #cells do
      local cell = cells[col]
      if cell and cell_has_content(cell) then
        append_cell(cell, col)
      else
        flush_column(col)
      end
    end
  end

  if tbl.head and tbl.head.rows then
    for _, row in ipairs(tbl.head.rows) do
      process_row(row.cells)
    end
  end

  if tbl.bodies then
    for _, body in ipairs(tbl.bodies) do
      if body.head and body.head.rows then
        for _, row in ipairs(body.head.rows) do
          process_row(row.cells)
        end
      end
      if body.body then
        for _, row in ipairs(body.body) do
          process_row(row.cells)
        end
      end
    end
  end

  if tbl.foot and tbl.foot.rows then
    for _, row in ipairs(tbl.foot.rows) do
      process_row(row.cells)
    end
  end

  flush_all_columns()

  if column_mode_enabled then
    for _, col in ipairs(column_mode.columns) do
      blocks:extend(column_buffers[col])
    end
  end

  return blocks
end

local function handle_table(tbl)
  if should_flatten(tbl) then
    return flatten_table(tbl)
  end
  return nil
end

return {{ Table = handle_table }}
