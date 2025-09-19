-- split-inline-images.lua
-- In table cells, split a paragraph that mixes text + image into separate blocks
local function split_para(inlines)
  local blocks, buf = {}, pandoc.Inlines()
  local function flush_text()
    if #buf > 0 then table.insert(blocks, pandoc.Para(buf)); buf = pandoc.Inlines() end
  end
  for _, inl in ipairs(inlines) do
    if inl.t == "Image" then
      flush_text()
      table.insert(blocks, pandoc.Para(pandoc.Inlines(inl)))
    else
      buf:insert(inl)
    end
  end
  flush_text()
  return blocks
end

return {
  {
    Table = function(t)
      -- Handle both old and new Pandoc table formats
      local function process_rows(rows)
        for _, row in ipairs(rows) do
          for ci, cellBlocks in ipairs(row.c or row.cells or row) do
            if type(cellBlocks) == "table" then
              local newBlocks = {}
              for _, b in ipairs(cellBlocks) do
                if b and b.t == "Para" then
                  local pieces = split_para(b.content or b.c)
                  -- only replace when we actually split into >1 block
                  if #pieces > 1 then
                    for _, nb in ipairs(pieces) do table.insert(newBlocks, nb) end
                  else
                    table.insert(newBlocks, b)
                  end
                else
                  table.insert(newBlocks, b)
                end
              end
              if row.c then
                row.c[ci] = newBlocks
              elseif row.cells then
                row.cells[ci] = newBlocks
              end
            end
          end
        end
      end

      -- Process table bodies (new format)
      if t.bodies then
        for _, body in ipairs(t.bodies) do
          if body.body then
            process_rows(body.body)
          end
        end
      end
      
      -- Process table rows (old format fallback)
      if t.c and t.c[1] then
        process_rows(t.c[1])
      end
      
      return t
    end
  }
}