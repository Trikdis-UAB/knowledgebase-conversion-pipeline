-- fix-admonition-lists.lua
-- Fixes broken numbering in ordered lists within Div containers (admonitions)
--
-- Problem: After DOCX conversion, lists in admonitions sometimes start at wrong numbers
-- Example: List starts at 2 instead of 1, often because it references image callout numbers
--
-- Solution: Reset ordered lists to start at 1 when they appear to be incorrectly numbered

function Div(div)
  -- Check if this might be an admonition (has classes)
  if not div.classes or #div.classes == 0 then
    return div
  end

  -- Check if it looks like an admonition class
  local is_admonition = false
  for _, class in ipairs(div.classes) do
    if class == "note" or class == "important" or class == "warning" or
       class == "caution" or class == "tip" or class:match("^admonition") then
      is_admonition = true
      break
    end
  end

  -- Also process divs without specific classes - they might still be admonitions
  -- that haven't been fully processed yet

  -- Walk through the div content looking for ordered lists
  local new_content = {}
  local changed = false

  for i, block in ipairs(div.content) do
    if block.t == 'OrderedList' then
      -- Check if list starts at a number other than 1
      if block.start and block.start > 1 then
        -- Reset to start at 1
        block.start = 1
        changed = true
      end
      table.insert(new_content, block)
    else
      table.insert(new_content, block)
    end
  end

  if changed then
    div.content = new_content
    return div
  end

  return div
end

-- NOTE: A previous global OrderedList() handler that reset all lists with
-- start >= 2 to 1 was removed because it conflicts with maintain-list-continuity.lua,
-- which correctly sets continuation start numbers for multi-step numbered procedures
-- (e.g. Quick Installation Guides where each step is a separate ordered list broken
-- by images).  Admonition-internal lists are already covered by the Div() handler above.

function Para(p)
  if not p.content or #p.content == 0 then
    return nil
  end

  local new_content = pandoc.List()
  local changed = false
  local previous = nil

  for _, inline in ipairs(p.content) do
    local strip = false

    if inline.t == 'Str' and (inline.text == '>' or inline.c == '>') then
      if previous and (previous.t == 'SoftBreak' or (previous.t == 'Str' and previous.text == '!!!')) then
        strip = true
      end
    end

    if strip then
      changed = true
    else
      new_content:insert(inline)
    end

    if not strip then
      previous = inline
    end
  end

  if changed then
    p.content = new_content
    return p
  end

  return nil
end

return {
  {Div = Div, Para = Para}
}
