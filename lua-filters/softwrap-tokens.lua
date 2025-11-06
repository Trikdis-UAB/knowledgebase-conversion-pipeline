-- softwrap-tokens.lua
-- Insert zero-width spaces after "/" and ";" inside 2-col tables
local ZWSP = utf8.char(0x200B)

local function soften(text)
  -- don't touch URLs
  if text:match("https?://") then return text end
  text = text:gsub("/", "/" .. ZWSP)
  text = text:gsub(";", ";" .. ZWSP)
  return text
end

return {
  {
    Table = function(tbl)
      -- apply to all 2-col tables (class "two-col" if present OR exactly 2 cells)
      local classes = tbl.attr and tbl.attr.classes or {}
      local has_two_col_class = false
      for _,c in ipairs(classes) do if c == "two-col" then has_two_col_class = true end end

      local function count_cols(t)
        -- Handle different Pandoc table formats
        if t.head and t.head.c and #t.head.c > 0 then
          return #t.head.c
        end
        if t.headers and #t.headers > 0 then 
          return #t.headers 
        end
        if t.bodies and #t.bodies > 0 then
          local firstBody = t.bodies[1]
          if firstBody and firstBody.body and #firstBody.body > 0 then
            local firstRow = firstBody.body[1]
            if firstRow and firstRow.cells then
              return #firstRow.cells
            end
          end
        end
        -- Fallback: try to count from colgroup
        if t.colspecs and #t.colspecs > 0 then
          return #t.colspecs
        end
        return 0
      end
      local is_two_col = has_two_col_class or count_cols(tbl) == 2
      if not is_two_col then return nil end

      return pandoc.walk_block(tbl, {
        Str = function(el) el.text = soften(el.text); return el end
      })
    end
  }
}