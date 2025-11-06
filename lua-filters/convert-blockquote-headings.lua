-- convert-blockquote-headings.lua
-- Converts blockquotes that are misused as section headings into proper markdown headings
--
-- Handles two patterns:
-- 1. Blockquote containing only bold text: > **Section Title** → #### Section Title
-- 2. Blockquote wrapping heading: > #### Section Title → #### Section Title
--
-- This is common in DOCX conversions where formatting creates unwanted blockquotes

local S = pandoc.utils.stringify

function BlockQuote(blockquote)
  -- Pattern 1: Blockquote wraps an actual heading element
  -- Example: > #### SMS command list (parsed as Header)
  if #blockquote.content == 1 and blockquote.content[1].t == 'Header' then
    -- Unwrap - return the heading directly
    return blockquote.content[1]
  end

  -- Check if blockquote contains only one paragraph
  if #blockquote.content ~= 1 or blockquote.content[1].t ~= 'Para' then
    return blockquote  -- Keep complex blockquotes as-is
  end

  local para = blockquote.content[1]

  -- Pattern 2: Paragraph that looks like a heading (starts with ####)
  -- Example: > #### SMS command list (parsed as Para with text)
  local text = S(para.content)
  local heading_match = text:match("^(#{1,6})%s+(.+)$")
  if heading_match then
    local hashes, title = text:match("^(#{1,6})%s+(.+)$")
    if hashes then
      local level = #hashes
      -- Extract the title without the hash marks
      -- Use the original content but skip the first element if it's just the hashes
      return pandoc.Header(level, {pandoc.Str(title)})
    end
  end

  -- Pattern 3: Blockquote contains only bold text
  -- Example: > **Schematics for connecting sensors.**
  if #para.content == 1 and para.content[1].t == 'Strong' then
    local bold_text = S(para.content[1])

    -- Check if it's substantive heading text (more than 3 chars, not ending with colon)
    if #bold_text >= 3 and not bold_text:match(':%s*$') then
      -- Convert to H4 heading
      return pandoc.Header(4, para.content[1].content)
    end
  end

  return blockquote  -- Keep as blockquote if none of the patterns match
end
