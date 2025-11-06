-- strip-toc.lua
-- Improved to handle multiple TOC formats at AST level
-- Detects TOC by:
-- 1. "Contents" or "Table of Contents" header (any level)
-- 2. Pattern of multiple internal links in paragraphs
-- Then skips all content until first real H2 section

local S = pandoc.utils.stringify
local skipping = false
local consecutive_link_paras = 0

local function normalize(text)
  return (text or ""):lower():gsub('%s+', ' ')
end

local function is_toc_heading(text)
  local normalized = normalize(text)
  return normalized:match('table of contents')
      or normalized:match('tabla de contenido')
      or normalized:match('contenidos?')
      or normalized:match('содержани[ея]')
      or normalized == 'contenido'
      or normalized == 'contents'
end

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

  -- Real headers that mark end of TOC:
  -- - H1 with Word styles (e.g., "Description" with .Pagrindinis class)
  -- - H2 headers like "Description", "Installation", etc.
  -- - NOT starting with numbers like "1.1 Feature"

  if header.level == 1 then
    -- H1 headers are always real content (e.g., Description, Installation)
    -- Check if it's not just a number (like in TOC)
    if not text:match('^%s*%d+%.?%d*%s*$') then
      return true
    end
  end

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
          if is_toc_heading(text) then
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
        if b.t == 'Header' and is_real_header(b) and not is_toc_heading(S(b.content)) then
          -- Found real content section, stop skipping
          skipping = false
          consecutive_link_paras = 0
          table.insert(out, b)
        elseif b.t == 'Para' and not has_internal_links(b) then
          local text = normalize(S(b.content))
          if text ~= '' then
            skipping = false
            table.insert(out, b)
          end
        end
        -- All other blocks dropped while skipping
      end
    end

    return out
  end
}
