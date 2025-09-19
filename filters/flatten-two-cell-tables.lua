-- flatten-two-cell-tables.lua (robust: handles header-only and body-only single-row tables)
local S = pandoc.utils.stringify

-- Grab first and only row across head+body if total rows == 1
local function get_single_row(tbl)
  local head_rows = (tbl.head and tbl.head.rows) or {}
  local body_rows = {}
  if tbl.bodies and tbl.bodies[1] and tbl.bodies[1].body then
    body_rows = tbl.bodies[1].body
  end
  local total = #head_rows + #body_rows
  if total ~= 1 then return nil end
  return (#head_rows == 1) and head_rows[1] or body_rows[1]
end

local function has_image(blocks)
  local found = false
  pandoc.walk_block(pandoc.Div(blocks), { Image = function() found = true end })
  return found
end

local function is_textual(blocks)
  local txt = S(pandoc.Div(blocks)):gsub("%s+","")
  return txt ~= ""
end

local function strip_bold_blocks(blocks)
  return pandoc.walk_block(pandoc.Div(blocks), { Strong = function(el) return el.c end }).content
end

local function blocks_to_md(blocks)
  return pandoc.write(pandoc.Pandoc(blocks, pandoc.Meta{}), "commonmark_x")
end

-- helper to convert blocks to HTML
local function blocks_to_html(blocks)
  return pandoc.write(pandoc.Pandoc(blocks, pandoc.Meta{}), "html")
end

-- NEW: extract short title + leftover blocks from left cell
local function split_title_and_rest(left_blocks)
  -- render left cell to Markdown to detect first line / colon
  local md = blocks_to_md(left_blocks):gsub("\r\n","\n"):gsub("^%s+",""):gsub("%s+$","")
  
  -- Handle common patterns like "**Note:**" or "**Warning:**"
  local simple_pattern = md:match("^%*%*([^:*]+):%*%*$")
  if simple_pattern then
    return simple_pattern:gsub("^%s+",""):gsub("%s+$",""), {}
  end
  
  local first = md:match("^[^\n]+") or md
  local rest_md = md:match("\n(.+)$") or ""

  -- if colon appears in first line, split there
  local pre, post = first:match("^(.-):%s*(.*)$")
  local title_line, leftover_md
  if pre then
    title_line = pre
    leftover_md = (post ~= "" and (post.."\n"..rest_md) or rest_md)
  else
    title_line = first
    leftover_md = rest_md
  end

  -- strip formatting in title → plain text, trim & cap length
  local title_plain = pandoc.utils.stringify(pandoc.read(title_line, "commonmark")):gsub("^%s+",""):gsub("%s+$","")
  if #title_plain > 80 then
    -- too long for a title → no title, push everything to body
    return nil, pandoc.read(md, "commonmark").blocks
  end

  -- if title is empty or just formatting, use everything as body
  if title_plain == "" then
    return nil, pandoc.read(md, "commonmark").blocks
  end

  local leftover_blocks = {}
  if leftover_md and leftover_md:match("%S") then
    leftover_blocks = pandoc.read(leftover_md:gsub("^%s+",""), "commonmark").blocks
  end
  return title_plain, leftover_blocks
end

local function indent_md(md, n)
  local pad = string.rep(" ", n or 4)
  md = md:gsub("\r\n","\n")
  local out = {}
  for line in md:gmatch("([^\n]*)\n?") do
    if line == "" then table.insert(out, pad) else table.insert(out, pad .. line) end
  end
  return table.concat(out, "\n")
end

return {
  {
    Table = function(tbl)
      -- only act on exactly 1 row, 2 cells
      local row = get_single_row(tbl)
      if not row or not row.cells or #row.cells ~= 2 then return nil end
      local left_cell, right_cell = row.cells[1], row.cells[2]
      
      -- Extract the actual blocks from the cells
      local left = left_cell.contents
      local right = right_cell.contents

      local L_has_img, R_has_img = has_image(left), has_image(right)
      local L_text,    R_text    = is_textual(left), is_textual(right)

      -- A) text + image (either order) → text (no bold) above, image(s) below
      if (L_text and R_has_img and not L_has_img) or (R_text and L_has_img and not R_has_img) then
        local text_blocks  = L_text and left or right
        local image_blocks = L_has_img and left or right

        -- strip bold from text cell
        text_blocks = strip_bold_blocks(text_blocks)

        -- collect each image as its own paragraph (preserve order)
        local out_imgs = {}
        local function collect_images(b)
          if b.t == "Para" or b.t == "Plain" then
            for _, inl in ipairs(b.c or b.content or {}) do
              if inl.t == "Image" then
                table.insert(out_imgs, pandoc.Para(pandoc.Inlines(inl)))
              end
            end
          end
        end
        for _, b in ipairs(image_blocks) do collect_images(b) end

        local out = {}
        for _, b in ipairs(text_blocks)  do table.insert(out, b) end
        for _, b in ipairs(out_imgs)     do table.insert(out, b) end
        return out
      end

      -- B) text + text -> GitHub-style alerts (Typora-compatible)
      if L_text and R_text and (not L_has_img) and (not R_has_img) then
        local title, left_rest_blocks = split_title_and_rest(left)  -- from earlier patch
        local body_blocks = {}
        for _,b in ipairs(left_rest_blocks) do table.insert(body_blocks, b) end
        for _,b in ipairs(right)            do table.insert(body_blocks, b) end

        -- Map to GitHub alert types based on title
        local alert_type = "NOTE"
        if title and title:lower():match("^important%s*$") then 
          alert_type = "IMPORTANT" 
        elseif title and title:lower():match("^warning%s*$") then
          alert_type = "WARNING"
        elseif title and title:lower():match("^caution%s*$") then
          alert_type = "CAUTION"
        elseif title and title:lower():match("^tip%s*$") then
          alert_type = "TIP"
        end

        -- Convert body blocks to markdown
        local body_md = blocks_to_md(body_blocks)
        
        -- Format as GitHub-style alert
        local lines = {}
        table.insert(lines, "> [!" .. alert_type .. "]")
        
        -- Add each line of body with > prefix
        for line in body_md:gmatch("[^\n]*") do
          if line == "" then
            table.insert(lines, ">")
          else
            table.insert(lines, "> " .. line)
          end
        end
        
        local alert_md = table.concat(lines, "\n")
        return pandoc.RawBlock("markdown", alert_md)
      end

      return nil
    end
  }
}