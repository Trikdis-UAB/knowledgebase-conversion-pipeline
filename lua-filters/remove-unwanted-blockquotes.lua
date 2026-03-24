-- remove-unwanted-blockquotes.lua
-- Remove blockquotes that are just plain text or feature descriptions, not actual citations
--
-- Common in DOCX conversions where:
-- 1. Notes are wrapped in blockquotes
-- 2. Feature descriptions are incorrectly quoted
-- 3. Technical specifications are quoted when they shouldn't be

function BlockQuote(blockquote)
  -- Check if this blockquote contains text that should not be quoted
  local content = pandoc.utils.stringify(blockquote.content)

  -- Pattern 1: Remove blockquotes that contain notes about control panels, manufacturers, etc.
  if content:match("Control panels directly controlled") or
     content:match("Other manufacturers") or
     content:match("Underlined") or
     content:match("PARADOX security panels") then
    return blockquote.content
  end

  -- Pattern 2: Feature descriptions - Often start with "After the alarm" or "When the alarm"
  if content:match("^After the alarm") or
     content:match("^When the alarm") or
     content:match("^If the alarm") then
    return blockquote.content
  end

  -- Pattern 3: Zone behavior descriptions
  if content:match("zone is triggered") or
     content:match("zone is violated") or
     content:match("zone can also be triggered") then
    return blockquote.content
  end

  -- Pattern 4: System state descriptions
  if content:match("output signals? for") or
     content:match("report about.*is sent") or
     content:match("reports? are sent") then
    return blockquote.content
  end

  -- Pattern 5: SMS text matching patterns (often quoted incorrectly)
  if content:match("%%") or  -- Contains % symbol (pattern markers)
     content:match("The SMS message text is") then
    return blockquote.content
  end

  -- Pattern 6: Waste disposal and environmental information
  if content:match("Please adhere to your local waste sorting") or
     content:match("do not dispose of this equipment") then
    return blockquote.content
  end

  -- Generic rule: unwrap simple paragraph-only blockquotes that are not real
  -- quotations.  However, preserve blockquotes that contain hyperlinks or image
  -- references — those are intentional styled callouts (e.g. support banners,
  -- download instructions) and should remain as blockquotes.
  local all_plain = true
  for _, inner in ipairs(blockquote.content) do
    if inner.t ~= 'Para' and inner.t ~= 'Plain' then
      all_plain = false
      break
    end
  end

  if all_plain then
    -- Check for hyperlinks inside the blockquote content
    local has_link = false
    local has_image = false
    pandoc.walk_block(pandoc.Div(blockquote.content), {
      Link = function(_) has_link = true end,
      Image = function(_) has_image = true end,
      RawInline = function(ri)
        if ri.text:match('<img') or ri.text:match('http') then
          has_image = true
        end
      end
    })
    -- Also check stringified content for URLs (covers plain-text URLs too)
    if not has_link and content:match('https?://') then
      has_link = true
    end
    if not has_link and content:match('www%.') then
      has_link = true
    end

    if has_link or has_image then
      -- Keep as blockquote — it looks intentional (support link, download banner)
      return blockquote
    end

    return blockquote.content
  end

  -- For other blockquotes, keep them as-is (they might be actual citations)
  return blockquote
end
