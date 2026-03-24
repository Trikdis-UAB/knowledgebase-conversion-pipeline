-- normalize-sp3-title.lua
-- Ensure SP3 manuals get the expected localized H1 title.

local function make_title(language)
  if language == 'lt' then
    return {
      pandoc.Str('Apsaugos'),
      pandoc.Space(),
      pandoc.Str('centralė'),
      pandoc.Space(),
      pandoc.Str('“FLEXi”'),
      pandoc.Space(),
      pandoc.Str('SP3')
    }
  elseif language == 'es' then
    return {
      pandoc.Str('Panel'),
      pandoc.Space(),
      pandoc.Str('de'),
      pandoc.Space(),
      pandoc.Str('control'),
      pandoc.Space(),
      pandoc.Str('FLEXi'),
      pandoc.Space(),
      pandoc.Str('SP3')
    }
  elseif language == 'ru' then
    return {
      pandoc.Str('Охранная'),
      pandoc.Space(),
      pandoc.Str('панель'),
      pandoc.Space(),
      pandoc.Str('„FLEXI“'),
      pandoc.Space(),
      pandoc.Str('SP3')
    }
  end

  return {
    pandoc.Str('Security'),
    pandoc.Space(),
    pandoc.Str('control'),
    pandoc.Space(),
    pandoc.Str('panel'),
    pandoc.Space(),
    pandoc.Str('“FLEXi”'),
    pandoc.Space(),
    pandoc.Str('SP3')
  }
end

local function expected_title(language)
  if language == 'lt' then
    return 'Apsaugos centralė “FLEXi” SP3'
  elseif language == 'es' then
    return 'Panel de control FLEXi SP3'
  elseif language == 'ru' then
    return 'Охранная панель „FLEXI“ SP3'
  end

  return 'Security control panel “FLEXi” SP3'
end

local function normalize_text(text)
  return text:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
end

local function is_sp3_doc(blocks)
  -- Require BOTH "FLEXi" AND "SP3" to appear in the first 15 blocks (title area).
  -- This prevents false-positive matches when other manuals merely reference SP3
  -- as a compatible device in their body text (e.g., iO-8 mentions "SP3" in its
  -- list of compatible main units, but the document is not about the SP3 panel).
  local limit = math.min(#blocks, 15)
  local has_flexi = false
  local has_sp3 = false
  for i = 1, limit do
    local block = blocks[i]
    if block.t == 'Para' or block.t == 'Plain' or block.t == 'Header' then
      local text = pandoc.utils.stringify(block)
      if text:match('FLEXi') or text:match('FLEXI') then
        has_flexi = true
      end
      if text:match('SP3') then
        has_sp3 = true
      end
    end
  end
  return has_flexi and has_sp3
end

local function detect_language(blocks)
  local limit = math.min(#blocks, 80)
  for i = 1, limit do
    local block = blocks[i]
    if block.t == 'Para' or block.t == 'Plain' or block.t == 'Header' then
      local text = pandoc.utils.stringify(block)
      local lowered = text:lower()

      if text:match('[Оо]хран') or text:match('[Пп]ольз') or text:match('[Оо]писан') then
        return 'ru'
      end
      if lowered:match('apsaugos') or lowered:match('vartotojai') or lowered:match('aprašymas') then
        return 'lt'
      end
      -- Match accent-insensitive substrings to tolerate encoding artifacts.
      if lowered:match('descripci[óo]n') or lowered:match('descripci%?n')
         or lowered:match('caracter[íi]sticas') or lowered:match('tabla de contenido')
         or lowered:match('usuarios') or text:match('¿') then
        return 'es'
      end
    end
  end
  return 'en'
end

local function looks_like_bad_title(text)
  return #normalize_text(text) > 60
end

local function is_title_candidate(text)
  return text:match('SP3') and (
    text:match('Security control panel')
    or text:match('Apsaugos centralė')
    or text:match('Panel de control')
    or text:match('[Оо]хранная панель')
    or text:match('FLEXi')
    or text:match('FLEXI')
  )
end

function Pandoc(doc)
  if not is_sp3_doc(doc.blocks) then
    return doc
  end

  local language = detect_language(doc.blocks)
  local title_text = expected_title(language)

  local title_applied = false
  for i, block in ipairs(doc.blocks) do
    if block.t == 'Header' and block.level == 1 then
      local text = normalize_text(pandoc.utils.stringify(block.content))
      if looks_like_bad_title(text) or is_title_candidate(text) then
        if text ~= title_text then
          block.content = make_title(language)
          doc.blocks[i] = block
        end
        title_applied = true
        break
      end
    end
  end

  if not title_applied then
    for i, block in ipairs(doc.blocks) do
      if block.t == 'Header' and block.level == 2 then
        local text = normalize_text(pandoc.utils.stringify(block.content))
        if is_title_candidate(text) then
        block.level = 1
        block.content = make_title(language)
        doc.blocks[i] = block
        title_applied = true
        break
        end
      end
    end
  end

  if not title_applied then
    table.insert(doc.blocks, 1, pandoc.Header(1, make_title(language)))
  end

  return doc
end

return {
  { Pandoc = Pandoc }
}
