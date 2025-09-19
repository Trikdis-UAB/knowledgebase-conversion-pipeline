-- flatten-two-cell-tables.lua
-- Convert single-row, two-column tables:
--  A) text + image  -> text above, image(s) below (strip bold in the text)
--  B) text + text   -> MkDocs admonition  !!! info "<left title>"\n    <right body>
--
-- No keywords; purely structural: exactly 1 row, 2 cells.

local S = pandoc.utils.stringify

-- helpers
local function is_two_column_simple_table(t)
  -- Check if table has exactly 2 columns
  if not t.colspecs or #t.colspecs ~= 2 then
    return false
  end
  
  -- Check if table structure is simple (empty body OR single-row body)
  if t.bodies and #t.bodies > 0 then
    local tbody = t.bodies[1]
    if tbody.body then
      -- Either empty body (content in header) or exactly 1 row in body
      if #tbody.body == 0 or #tbody.body == 1 then
        return true
      end
    end
  end
  
  return false
end

local function extract_content_by_position(t)
  -- For 2-column tables, collect all content and divide it roughly in half
  -- This is a heuristic since we can't directly access cell boundaries
  
  local all_images = {}
  local all_text_blocks = {}
  
  -- Collect all content from the table
  pandoc.walk_block(t, {
    Image = function(img)
      table.insert(all_images, img)
    end,
    Para = function(para)
      if S(para):gsub("%s+", "") ~= "" then
        table.insert(all_text_blocks, para)
      end
    end,
    Plain = function(plain)
      if S(plain):gsub("%s+", "") ~= "" then
        table.insert(all_text_blocks, plain)
      end
    end
  })
  
  -- For a 2-column table, assume first half goes to left, second half to right
  local mid_text = math.ceil(#all_text_blocks / 2)
  local mid_img = math.ceil(#all_images / 2)
  
  local left_text = {}
  local right_text = {}
  local left_images = {}
  local right_images = {}
  
  -- Split text blocks
  for i, block in ipairs(all_text_blocks) do
    if i <= mid_text then
      table.insert(left_text, block)
    else
      table.insert(right_text, block)
    end
  end
  
  -- Split images
  for i, img in ipairs(all_images) do
    if i <= mid_img then
      table.insert(left_images, img)
    else
      table.insert(right_images, img)
    end
  end
  
  return {
    [1] = {
      images = left_images,
      text_blocks = left_text,
      has_image = #left_images > 0,
      has_text = #left_text > 0
    },
    [2] = {
      images = right_images,
      text_blocks = right_text,
      has_image = #right_images > 0,
      has_text = #right_text > 0
    }
  }
end

local function flatten_strong_inlines(inlines)
  return pandoc.walk_inline(inlines, {
    Strong = function(el) return el.c end
  })
end

local function flatten_strong_blocks(blocks)
  local result = {}
  for _, block in ipairs(blocks) do
    local modified = pandoc.walk_block(block, {
      Strong = function(el) return el.c end
    })
    table.insert(result, modified)
  end
  return result
end

local function blocks_to_markdown(blocks)
  return pandoc.write(pandoc.Pandoc(blocks, pandoc.Meta{}), "commonmark_x")
end

local function indent_md(md, n)
  local pad = string.rep(" ", n or 4)
  md = md:gsub("\r\n", "\n")
  local out = {}
  for line in md:gmatch("([^\n]*)\n?") do
    if line == "" then
      table.insert(out, pad) -- preserve blank lines in indented block
    else
      table.insert(out, pad .. line)
    end
  end
  return table.concat(out, "\n")
end

return {
  {
    Table = function(t)
      if not is_two_column_simple_table(t) then return nil end
      
      local info = extract_content_by_position(t)
      local left = info[1]
      local right = info[2]

      -- A) text + image (in either order)
      if (left.has_text and right.has_image and not left.has_image)
         or (right.has_text and left.has_image and not right.has_image) then

        local text_info  = left.has_text  and left  or right
        local image_info = left.has_image and left  or right

        -- strip bold in text blocks
        local text_blocks = flatten_strong_blocks(text_info.text_blocks)

        -- create image paragraphs
        local out_imgs = {}
        for _, img in ipairs(image_info.images) do
          table.insert(out_imgs, pandoc.Para(pandoc.Inlines(img)))
        end

        -- Output: text blocks (no bold) followed by images
        local out = {}
        for _, b in ipairs(text_blocks) do table.insert(out, b) end
        for _, b in ipairs(out_imgs) do table.insert(out, b) end
        return out
      end

      -- B) text + text (no images) -> admonition
      if left.has_text and right.has_text and (not left.has_image) and (not right.has_image) then
        -- Get title from left cell
        local title_text = ""
        for _, block in ipairs(left.text_blocks) do
          title_text = title_text .. S(block)
        end
        title_text = title_text:gsub("^%s+",""):gsub("%s+$","")
        if title_text == "" then title_text = "Info" end
        
        -- Get body from right cell
        local body_md = blocks_to_markdown(right.text_blocks)
        local raw = string.format('!!! info "%s"\n%s', title_text, indent_md(body_md, 4))
        return pandoc.RawBlock("markdown", raw)
      end

      return nil
    end
  }
}