-- normalize-sp3-title.lua
-- Ensure SP3 manuals get the expected H1 title "Panel de control FLEXi SP3"

local function make_title()
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
end

local function is_sp3_doc(blocks)
  local limit = math.min(#blocks, 40)
  for i = 1, limit do
    local block = blocks[i]
    if block.t == 'Para' or block.t == 'Plain' or block.t == 'Header' then
      local text = pandoc.utils.stringify(block)
      if text:match('SP3') or text:match('FLEXi') then
        return true
      end
    end
  end
  return false
end

local function is_spanish_doc(blocks)
  local limit = math.min(#blocks, 80)
  for i = 1, limit do
    local block = blocks[i]
    if block.t == 'Para' or block.t == 'Plain' or block.t == 'Header' then
      local text = pandoc.utils.stringify(block):lower()
      -- Match accent-insensitive substrings to tolerate encoding artifacts (descripci?n, garant?a, etc.)
      if text:match('descripci[óo]n') or text:match('descripci%?n')
         or text:match('caracter[íi]sticas') or text:match('tabla de contenido')
         or text:match('¿') then
        return true
      end
    end
  end
  return false
end

local function looks_like_spanish_title(blocks)
  for _, block in ipairs(blocks) do
    if block.t == "Header" then
      local text = pandoc.utils.stringify(block.content or block):lower()
      if text:match("panel de control") then
        return true
      end
    elseif block.t == "Para" or block.t == "Plain" then
      local text = pandoc.utils.stringify(block):lower()
      if text:match("el panel de control") then
        return true
      end
    end
  end
  return false
end

function Pandoc(doc)
  if not is_sp3_doc(doc.blocks) then
    return doc
  end

  local spanish = is_spanish_doc(doc.blocks) or looks_like_spanish_title(doc.blocks)
  if not spanish then
    return doc
  end

  local title_applied = false
  for i, block in ipairs(doc.blocks) do
    if block.t == 'Header' then
      local text = pandoc.utils.stringify(block.content):lower():gsub('%s+', ' ')
      if block.level == 1 then
        block.content = make_title()
        doc.blocks[i] = block
        title_applied = true
        break
      elseif block.level == 2 and text:match('panel de control') then
        block.level = 1
        block.content = make_title()
        doc.blocks[i] = block
        title_applied = true
        break
      end
    end
  end

  if not title_applied then
    table.insert(doc.blocks, 1, pandoc.Header(1, make_title()))
  end

  return doc
end

return {
  { Pandoc = Pandoc }
}
