--[[
Relocate Warranty/Safety Sections Filter

Collects sections such as "Warranty", "Safety requirements", "Precauciones de seguridad",
 etc., regardless of whether they are represented as headings or bold paragraphs,
 removes them from their original location, and appends them near the end of the
 document (before Annex sections if present).
]]

local warranty_patterns = {
  -- English
  "^safety requirements$",
  "^safety precautions$",
  "^warranty and limitation of liability$",
  "^warranty$",
  -- Lithuanian
  "^saugos reikalavimai$",
  "^saugos atsargumo priemonės$",
  "^garantija ir atsakomybės apribojimas$",
  -- Spanish
  "^requisitos de seguridad$",
  "^requerimientos de seguridad$",
  "^precauciones de seguridad$",
  "^precauciones para la seguridad$",
  "^medidas de precaucion$",
  "^garantía y limitación de responsabilidad$",
  "^garantia y limitacion de responsabilidad$",
  -- Russian
  "^требования безопасности$",
  "^меры предосторожности$",
  "^гарантия и ограничение ответственности$",
}

local stop_patterns = {
  "^description$",
  "^aprašymas$",
  "^aprasymas$",
  "^descripción$",
  "^descripcion$",
  "^описание$",
  "^overview$",
}

local annex_patterns = {
  "^annex",
  "^priedas",
  "^anexo",
  "^приложение",
}

local function normalize(text)
  local lowered
  if pandoc.text and pandoc.text.lower then
    lowered = pandoc.text.lower(text)
  else
    lowered = text:lower()
  end
  lowered = lowered:gsub('["“”„]+', '')
  lowered = lowered:gsub("'", '')
  lowered = lowered:gsub("%s+", " ")
  lowered = lowered:gsub("^%s+", "")
  lowered = lowered:gsub("%s+$", "")
  lowered = lowered:gsub("[%.:;,-]+$", "")
  local replacements = {
    ['á'] = 'a', ['à'] = 'a', ['ä'] = 'a', ['â'] = 'a', ['ã'] = 'a',
    ['č'] = 'c', ['ć'] = 'c', ['ç'] = 'c',
    ['é'] = 'e', ['è'] = 'e', ['ë'] = 'e', ['ê'] = 'e',
    ['í'] = 'i', ['ì'] = 'i', ['ï'] = 'i', ['î'] = 'i',
    ['ñ'] = 'n',
    ['ó'] = 'o', ['ò'] = 'o', ['ö'] = 'o', ['ô'] = 'o', ['õ'] = 'o',
    ['ú'] = 'u', ['ù'] = 'u', ['ü'] = 'u', ['û'] = 'u',
    ['ý'] = 'y', ['ÿ'] = 'y',
    ['š'] = 's', ['ž'] = 'z'
  }
  lowered = lowered:gsub('[áàäâãčćçéèëêíìïîñóòöôõúùüûýÿšž]', replacements)
  return lowered
end

local function matches_any(text, patterns, normalized)
  local normalized = normalized or normalize(text)
  for _, pattern in ipairs(patterns) do
    if normalized:match(pattern) then
      return true
    end
  end
  return false
end

local function is_warranty_heading(text)
  local normalized = normalize(text)
  if matches_any(text, warranty_patterns, normalized) then
    return true
  end
  if normalized:match('medidas') and normalized:match('precauc') then
    return true
  end
  if normalized:match('garant') and normalized:match('responsabil') then
    return true
  end
  if normalized:match('precauc') and normalized:match('seguridad') then
    return true
  end
  if normalized:match('requerim') and normalized:match('seguridad') then
    return true
  end
  if normalized:match('safety') and (normalized:match('requirements') or normalized:match('precautions')) then
    return true
  end
  return false
end

local function is_stop_heading(text)
  return matches_any(text, stop_patterns)
end

local function is_annex_heading(text)
  return matches_any(text, annex_patterns)
end

local function is_warranty_paragraph(block)
  if block.t ~= "Para" then
    return nil
  end
  for _, inline in ipairs(block.content) do
    if inline.t == "Strong" or inline.t == "SmallCaps" then
      local text = pandoc.utils.stringify(inline)
      if is_warranty_heading(text) then
        return text
      end
    end
  end
  return nil
end

local function trim_leading_blank(blocks)
  while #blocks > 0 do
    local first = blocks[1]
    if first.t == "Para" and pandoc.utils.stringify(first):match("^%s*$") then
      table.remove(blocks, 1)
    else
      break
    end
  end
end

local function is_cover_image_para(para)
  if para.t ~= "Para" then
    return false
  end
  for _, inline in ipairs(para.content) do
    if inline.t == "RawInline" and inline.format == "html" then
      local html = inline.text or inline.c[2]
      local src = html:match('src="([^"]+)"')
      if src and src:match('%.?/image1%.png') then
        return true
      end
    elseif inline.t == "Image" then
      local src = inline.c[2][1]
      if src and src:match('image1%.png') then
        return true
      end
    elseif inline.t ~= "Space" and inline.t ~= "SoftBreak" then
      return false
    end
  end
  return false
end

local function trim_trailing_cover_image(blocks)
  while #blocks > 0 do
    local last = blocks[#blocks]
    if last.t == "Div" then
      local attr, inner = table.unpack(last.c)
      if inner and #inner == 1 and is_cover_image_para(inner[1]) then
        table.remove(blocks, #blocks)
      else
        break
      end
    elseif is_cover_image_para(last) then
      table.remove(blocks, #blocks)
    else
      break
    end
  end
end

local function collect_section(blocks, start_index, heading_level)
  local collected = pandoc.List()
  local i = start_index
  while i <= #blocks do
    local block = blocks[i]
    local stop = false

    if block.t == "Header" then
      local text = pandoc.utils.stringify(block)
      if is_warranty_heading(text) then
        stop = true
      elseif block.level <= heading_level then
        stop = true
      elseif block.level <= 2 then
        stop = true
      elseif is_stop_heading(text) then
        stop = true
      end
    elseif block.t == "Para" then
      if is_warranty_paragraph(block) then
        stop = true
      end
    end

    if stop then
      break
    end

    collected:insert(block)
    i = i + 1
  end

  trim_leading_blank(collected)
  trim_trailing_cover_image(collected)
  return collected, i
end

local function is_nonempty_text_block(block)
  if (block.t == "Para" or block.t == "Plain") and block.content then
    local text = pandoc.utils.stringify(block)
    if text and text:match('%S') then
      return true
    end
  end
  return false
end

local function find_first_stop_index(blocks)
  for idx, block in ipairs(blocks) do
    if block.t == "Header" then
      local text = pandoc.utils.stringify(block)
      if is_stop_heading(text) then
        return idx
      end
    end
  end
  return nil
end

function Pandoc(doc)
  local blocks = doc.blocks
  local remaining = pandoc.List()
  local sections = {}

  local i = 1
  local main_started = false
  local first_stop_index = find_first_stop_index(blocks)
  while i <= #blocks do
    local block = blocks[i]
    local heading_text = nil
    local heading_level = 2
    local skip_current = false
    local before_main = false

    if first_stop_index then
      before_main = i < first_stop_index
    else
      before_main = not main_started
    end

    if block.t == "Header" then
      local text = pandoc.utils.stringify(block)
      local normalized = normalize(text)
      local stop_heading = is_stop_heading(text)
      local treat_as_section = false
      if is_warranty_heading(text) then
        treat_as_section = true
      elseif before_main and block.level >= 2 and not stop_heading then
        treat_as_section = true
      end

      if treat_as_section then
        heading_text = text
        heading_level = block.level
        skip_current = true
        i = i + 1
      end

      if stop_heading then
        main_started = true
      end
    elseif block.t == "Para" then
      local para_heading = is_warranty_paragraph(block)
      if para_heading then
        heading_text = para_heading
        heading_level = 2
        skip_current = true
        i = i + 1
      elseif not main_started and is_nonempty_text_block(block) then
        main_started = true
      end
    elseif block.t == "Plain" then
      if not main_started and is_nonempty_text_block(block) then
        main_started = true
      end
    end

    if heading_text then
      local content, next_index = collect_section(blocks, i, heading_level)
      local heading = pandoc.Header(2, {pandoc.Str(heading_text)})
      table.insert(sections, {heading = heading, blocks = content})
      i = next_index
    else
      remaining:insert(block)
      i = i + 1
    end
  end

  if #sections == 0 then
    return pandoc.Pandoc(blocks, doc.meta)
  end

  local insert_index = #remaining + 1
  for idx, block in ipairs(remaining) do
    if block.t == "Header" and block.level == 2 then
      local text = pandoc.utils.stringify(block)
      if is_annex_heading(text) then
        insert_index = idx
        break
      end
    end
  end

  local to_insert = pandoc.List()
  for _, section in ipairs(sections) do
    if #to_insert > 0 then
      to_insert:insert(pandoc.Para({}))
    end
    to_insert:insert(section.heading)
    for _, b in ipairs(section.blocks) do
      to_insert:insert(b)
    end
  end

  -- Avoid trailing blank paragraph
  if #to_insert > 0 then
    local last = to_insert[#to_insert]
    if last and last.t == "Para" and pandoc.utils.stringify(last):match("^%s*$") then
      to_insert[#to_insert] = nil
    end
  end

  for offset, block in ipairs(to_insert) do
    table.insert(remaining, insert_index + offset - 1, block)
  end

  return pandoc.Pandoc(remaining, doc.meta)
end

return {
  { Pandoc = Pandoc }
}
