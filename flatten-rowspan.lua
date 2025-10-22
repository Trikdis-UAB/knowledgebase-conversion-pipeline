-- flatten-rowspan.lua
-- Flattens rowspan cells in tables by duplicating content across rows
-- This allows tables to be converted to pipe format

function Table(tbl)
  -- Pandoc table structure:
  -- tbl.bodies is a list of TableBody
  -- Each TableBody has .body (list of rows) and .head (list of rows)
  -- Each Row has .cells (list of Cell)
  -- Each Cell has .row_span and .col_span
  
  if not tbl.bodies or #tbl.bodies == 0 then
    return tbl
  end
  
  local body = tbl.bodies[1]
  local new_rows = {}
  local pending_spans = {}  -- {col_index = {cell, remaining}}
  
  for _, row in ipairs(body.body) do
    local new_cells = {}
    local src_col = 1
    local dest_col = 1

    -- Calculate total columns needed for this row
    local total_cols = 0
    for i = 1, 100 do  -- reasonable max
      if pending_spans[i] or (src_col + (i - dest_col) <= #row.cells) then
        total_cols = i
      else
        break
      end
    end

    -- Process each column position
    for col = 1, total_cols do
      -- Check if we have a pending rowspan cell for this column
      if pending_spans[col] then
        local span_data = pending_spans[col]
        -- Create a proper clone of the cell
        local cloned_cell = {
          attr = span_data.cell.attr,
          alignment = span_data.cell.alignment,
          contents = span_data.cell.contents,
          col_span = span_data.cell.col_span,
          row_span = 1  -- Always 1 for flattened cells
        }
        table.insert(new_cells, cloned_cell)

        -- Decrement remaining count
        span_data.remaining = span_data.remaining - 1
        if span_data.remaining == 0 then
          pending_spans[col] = nil
        end
      else
        -- Use cell from current row
        if src_col <= #row.cells then
          local cell = row.cells[src_col]

          -- Check for rowspan
          local row_span = cell.row_span or 1

          -- Add to current row (with rowspan removed)
          cell.row_span = 1
          table.insert(new_cells, cell)

          -- If rowspan > 1, save for future rows
          if row_span > 1 then
            pending_spans[col] = {
              cell = cell,
              remaining = row_span - 1
            }
          end

          src_col = src_col + 1
        end
      end
    end

    -- Create new row with flattened cells
    row.cells = new_cells
    table.insert(new_rows, row)
  end
  
  -- Replace body with flattened rows
  body.body = new_rows
  
  return tbl
end
