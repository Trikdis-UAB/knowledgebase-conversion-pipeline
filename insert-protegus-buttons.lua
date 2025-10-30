-- insert-protegus-buttons.lua
-- Inject Protegus button HTML into numbered steps that reference the app download.

local html_buttons = table.concat({
  '<div style="margin: 20px 0; text-align: left;">',
  '  <a href="https://play.google.com/store/apps/details?id=lt.apps.protegus2" target="_blank" style="display: inline-block; margin-right: 10px;">',
  '    <img src="./protegus-android.png" alt="Get it on Google Play" style="height:50px;">',
  '  </a>',
  '  <a href="https://www.protegus.app" target="_blank" style="display: inline-block; margin-right: 10px;">',
  '    <img src="./protegus-web.png" alt="Open Web App" style="height:50px;">',
  '  </a>',
  '  <a href="https://apps.apple.com/us/app/protegus-2/id1555450252" target="_blank" style="display: inline-block;">',
  '    <img src="./protegus-ios.png" alt="Download on the App Store" style="height:50px;">',
  '  </a>',
  '</div>'
}, '\n')

local patterns = {
  "download.-protegus2",
  "instal.-protegus2",
  "atsisi.-protegus2",
  "parsisi.-protegus2",
  "aplicaci[óo]n.-protegus2",
  "web%.protegus%.app",
  "www%.protegus%.eu/login",
  "www%.protegus%.app"
}

local function stringify_blocks(blocks)
  local parts = {}
  for _, block in ipairs(blocks) do
    parts[#parts + 1] = pandoc.utils.stringify(block)
  end
  return table.concat(parts, " "):lower()
end

local function matches(blocks)
  local text = stringify_blocks(blocks)
  for _, pat in ipairs(patterns) do
    if text:match(pat) then
      return true
    end
  end
  return false
end

local function has_buttons(blocks)
  for _, block in ipairs(blocks) do
    if block.t == 'RawBlock' and block.format == 'html' and block.text:find('protegus%-android') then
      return true
    end
  end
  return false
end

local function strip_leading_number(para)
  if #para.content == 0 then
    return
  end
  local first = para.content[1]
  if first.t == 'Str' then
    local text = first.text
    local stripped = text:gsub('^%s*%d+%.?', '')
    if stripped ~= text then
      if stripped == '' then
        table.remove(para.content, 1)
        if para.content[1] and para.content[1].t == 'Space' then
          table.remove(para.content, 1)
        end
      else
        first.text = stripped
        if para.content[2] and para.content[2].t == 'Space' then
          table.remove(para.content, 2)
        end
      end
    end
  end
end

function OrderedList(list)
  local changed = false
  for _, item in ipairs(list.content) do
    if not has_buttons(item) and matches(item) then
      if item[1] and item[1].t == 'Para' then
        strip_leading_number(item[1])
      end
      table.insert(item, pandoc.RawBlock('html', html_buttons))
      changed = true
    end
  end
  return list
end

function BlockQuote(el)
  if #el.content == 1 and el.content[1].t == 'Para' then
    local para = el.content[1]
    local para_blocks = {para}
    if matches(para_blocks) then
      strip_leading_number(para)
      local item = {para, pandoc.RawBlock('html', html_buttons)}
      local list = pandoc.OrderedList({item})
      local processed = OrderedList(list)
      if processed then
        return processed
      end
      return list
    end
  elseif #el.content == 1 and el.content[1].t == 'OrderedList' then
    local list = el.content[1]
    local processed = OrderedList(list)
    if processed then
      return processed
    end
    return list
  end
  return el
end

function Pandoc(doc)
  local blocks = doc.blocks
  local i = 1
  while i < #blocks do
    local current = blocks[i]
    local nxt = blocks[i + 1]
    if current and nxt and current.t == 'OrderedList' and nxt.t == 'OrderedList' then
      local attrs_current, current_items = table.unpack(current.c)
      local attrs_next, next_items = table.unpack(nxt.c)
      if current_items and #current_items > 0 and matches(current_items[1]) then
        for _, item in ipairs(next_items or {}) do
          table.insert(current_items, item)
        end
        current.c = {attrs_current, current_items}
        table.remove(blocks, i + 1)
        goto continue
      end
    end
    i = i + 1
    ::continue::
  end
  return pandoc.Pandoc(blocks, doc.meta)
end
