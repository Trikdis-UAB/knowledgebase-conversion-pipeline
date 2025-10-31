-- remove-download-banners.lua
-- Drop legacy Protegus download image strips that duplicate the injected button block

local function is_banner_html(html)
  if not html then
    return false
  end
  if not html:match('<img') then
    return false
  end
  local src = html:match('src="([^"]+)"')
  if not src then
    return false
  end
  if src:match('protegus%-') then
    return false
  end
  if not src:match('image%d+%.png') then
    return false
  end
  local width = html:match('width:([%d%.]+)in')
  local height = html:match('height:([%d%.]+)in')
  width = tonumber(width)
  height = tonumber(height)
  if width and height then
    if width > 5 and width < 6.5 and height < 1.1 then
      return true
    end
  end
  return false
end

local function is_banner_para(para)
  if para.t ~= 'Para' and para.t ~= 'Plain' then
    return false
  end
  local saw_content = false
  for _, inline in ipairs(para.content) do
    if inline.t == 'RawInline' and inline.format == 'html' then
      if is_banner_html(inline.text or inline.c[2]) then
        saw_content = true
      else
        return false
      end
    elseif inline.t == 'Space' or inline.t == 'SoftBreak' then
      -- ignore
    elseif inline.t == 'Str' and inline.text:match('^%s*$') then
      -- ignore whitespace-like strings
    else
      return false
    end
  end
  return saw_content
end

local function is_banner_block(block)
  if block.t == 'RawBlock' and block.format == 'html' then
    return is_banner_html(block.text or block.c[2])
  end
  if block.t == 'Para' or block.t == 'Plain' then
    return is_banner_para(block)
  end
  return false
end

function Pandoc(doc)
  local blocks = doc.blocks
  local filtered = pandoc.List()
  local i = 1
  while i <= #blocks do
    local block = blocks[i]
    if block.t == 'OrderedList' then
      filtered:insert(block)
      local next_block = blocks[i + 1]
      while next_block and is_banner_block(next_block) do
        i = i + 1
        next_block = blocks[i + 1]
      end
    else
      if not is_banner_block(block) then
        filtered:insert(block)
      end
    end
    i = i + 1
  end
  return pandoc.Pandoc(filtered, doc.meta)
end

return {
  { Pandoc = Pandoc }
}
