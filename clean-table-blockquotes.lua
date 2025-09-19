-- clean-table-blockquotes.lua
-- Remove blockquotes from inside table cells, converting them to plain content

return {
  {
    Table = function(tbl)
      -- Process all table body cells to remove blockquotes
      if tbl.bodies then
        for _, body in ipairs(tbl.bodies) do
          if body.body then
            for _, row in ipairs(body.body) do
              if row.cells then
                for col_idx, cell in ipairs(row.cells) do
                  -- Cell is a list of blocks
                  local new_cell = {}
                  for _, block in ipairs(cell) do
                    if block.t == "BlockQuote" then
                      -- Extract content from blockquote and add directly
                      for _, inner in ipairs(block.content) do
                        table.insert(new_cell, inner)
                      end
                    else
                      table.insert(new_cell, block)
                    end
                  end
                  row.cells[col_idx] = new_cell
                end
              end
            end
          end
        end
      end
      
      return tbl
    end
  }
}