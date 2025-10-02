-- strip-toc.lua
-- Improved to handle multiple TOC formats at AST level
-- Detects TOC by:
-- 1. "Contents" or "Table of Contents" header (any level)
-- 2. Pattern of multiple internal links in paragraphs
-- Then skips all content until first real H2 section

local S = pandoc.utils.stringify
local skipping = false
local consecutive_link_paras = 0

-- Helper: Check if paragraph contains internal document links
local function has_internal_links(para)
  if para.t ~= 'Para' then return false end

  for _, inline in ipairs(para.content) do
    if inline.t == 'Link' then
      local target = inline.target
      -- Internal links start with #
      if target and target:match('^#') then
        return true
      end
    end
  end

  return false
end

-- Helper: Check if this is a real content header (not TOC)
local function is_real_header(header)
  if header.t ~= 'Header' then return false end

  local text = S(header.content)

  -- Real H2 headers that mark end of TOC:
  -- - "Description", "Installation", etc. (common section names)
  -- - NOT starting with numbers like "1.1 Feature"
  -- - Level 2 only (H2)

  if header.level == 2 then
    -- Check if it starts with a number
    if text:match('^%s*%d+%.?%d*%s') then
      return false  -- TOC subsection
    end

    -- Check if it ends with page number
    if text:match('%d+%s*$') then
      return false  -- TOC entry
    end

    -- Otherwise, it's likely a real section
    return true
  end

  return false
end

return {
  Blocks = function (blocks)
    local out = {}
    skipping = false
    consecutive_link_paras = 0

    for i, b in ipairs(blocks) do
      if not skipping then
        -- Check for TOC header
        if b.t == 'Header' then
          local text = S(b.content):lower():gsub('%s+', ' ')

          -- Look for "Contents" or "Table of Contents" at any level
          if text:match('contents') or text:match('table of contents') then
            skipping = true
            consecutive_link_paras = 0
            -- Don't add this header
          else
            table.insert(out, b)
            consecutive_link_paras = 0  -- Reset counter
          end

        -- Check for TOC link patterns
        elseif has_internal_links(b) then
          consecutive_link_paras = consecutive_link_paras + 1

          -- If we see 3+ consecutive paragraphs with internal links, it's a TOC
          if consecutive_link_paras >= 3 then
            skipping = true
            -- Remove the previous link paragraphs we added
            for j = 1, math.min(consecutive_link_paras - 1, #out) do
              if has_internal_links(out[#out]) then
                table.remove(out)
              else
                break
              end
            end
          else
            table.insert(out, b)
          end

        else
          table.insert(out, b)
          consecutive_link_paras = 0  -- Reset counter
        end

      else
        -- While skipping TOC
        if is_real_header(b) then
          -- Found real content section, stop skipping
          skipping = false
          consecutive_link_paras = 0
          table.insert(out, b)
        end
        -- All other blocks dropped while skipping
      end
    end

    return out
  end
}
