-- Bump tiny inline icons so they are readable in Markdown previews
local SMALL_THRESHOLD = 0.5
local SCALE_FACTOR = 3.0
local MIN_SIZE = 0.30

local function format_inches(value)
  return string.format('%.6fin', value)
end

local function scale_number(number)
  local num = tonumber(number)
  if not num or num > SMALL_THRESHOLD then
    return nil
  end
  local scaled = num * SCALE_FACTOR
  if scaled < MIN_SIZE then
    scaled = MIN_SIZE
  end
  return scaled
end

local function scale_style(style)
  local changed = false
  local function repl(kind)
    return function(_, num)
      local scaled = scale_number(num)
      if scaled then
        changed = true
        return kind .. format_inches(scaled)
      end
      return kind .. num .. 'in'
    end
  end
  local new_style = style:gsub('(width:)([%d%.%-%+eE]+)in', repl('width:'))
  new_style = new_style:gsub('(height:)([%d%.%-%+eE]+)in', repl('height:'))
  return new_style, changed
end

local function scale_html_fragment(text)
  local updated = text:gsub('style="([^"]+)"', function(style)
    local new_style, changed = scale_style(style)
    if changed then
      return 'style="' .. new_style .. '"'
    end
    return 'style="' .. style .. '"'
  end)
  if updated ~= text then
    return updated
  end
  return nil
end

local function handle_image(img)
  if not img.attributes then
    return nil
  end
  local style = img.attributes['style']
  if not style then
    return nil
  end
  local updated, changed = scale_style(style)
  if changed then
    img.attributes['style'] = updated
    return img
  end
  return nil
end

local function handle_raw(el)
  if el.format ~= 'html' then
    return nil
  end
  if not el.text:match('<img') then
    return nil
  end
  local updated = scale_html_fragment(el.text)
  if updated then
    return pandoc.RawInline('html', updated)
  end
  return nil
end

return {
  { Image = handle_image },
  { RawInline = handle_raw },
  { RawBlock = function(el)
      if el.format ~= 'html' then
        return nil
      end
      if not el.text:match('<img') then
        return nil
      end
      local updated = scale_html_fragment(el.text)
      if updated then
        return pandoc.RawBlock('html', updated)
      end
      return nil
    end
  }
}
