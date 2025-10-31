-- rewrite-protegus-links.lua
-- Normalize legacy Protegus URLs to https://www.protegus.app

local function normalized_target(target)
  if not target then
    return nil
  end

  target = target:gsub('^https?://', '')
  return target:lower()
end

local function replace_domain(url)
  if not url then
    return url
  end

  local lower = url:lower()
  if lower:match('web%.protegus%.app')
      or lower:match('www%.protegus%.eu/login')
      or lower:match('www%.protegus%.app')
      or lower:match('protegus%.eu') then
    return 'https://www.protegus.app'
  end

  return url
end

local function rewrite_display(inlines)
  local text = pandoc.utils.stringify(inlines):lower()
  if text:match('web%.protegus%.app')
      or text:match('www%.protegus%.eu/login')
      or text:match('www%.protegus%.app')
      or text:match('protegus%.eu') then
    return { pandoc.Str('www.protegus.app') }
  end
  return inlines
end

function Link(el)
  local new_target = replace_domain(el.target)
  if new_target ~= el.target then
    el.target = new_target
    el.content = rewrite_display(el.content)
  end
  return el
end

local function replace_text(text)
  local updated = text
  updated = updated:gsub('web%.protegus%.app', 'www.protegus.app')
  updated = updated:gsub('www%.protegus%.eu/login', 'www.protegus.app')
  updated = updated:gsub('www%.protegus%.eu', 'www.protegus.app')
  updated = updated:gsub('protegus%.eu', 'www.protegus.app')
  updated = updated:gsub('https?://[^%s%(%)]*www%.protegus%.app', 'https://www.protegus.app')
  return updated
end

function Str(el)
  local replaced = replace_text(el.text)
  if replaced ~= el.text then
    el.text = replaced
    return el
  end
  return nil
end

function RawInline(el)
  if el.format == 'html' then
    local replaced = replace_text(el.text)
    if replaced ~= el.text then
      el.text = replaced
      return el
    end
  end
  return nil
end

return {
  { Link = Link, Str = Str, RawInline = RawInline }
}
