-- reposition-sentence-splitting-images.lua
-- Detects images that split sentences and moves them above the paragraph
-- Pattern: "...text without period" → Image → "lowercase continuation..."

local function ends_with_sentence(text)
  -- Check if text ends with sentence-ending punctuation
  return text:match("[.!?]%s*$") ~= nil
end

local function starts_lowercase(text)
  -- Check if text starts with lowercase letter (continuation)
  local first_char = text:match("^%s*(%a)")
  return first_char and first_char:lower() == first_char
end

local function is_image_block(block)
  if block.t == "Para" and #block.content == 1 then
    return block.content[1].t == "Image"
  elseif block.t == "RawBlock" and block.format == "html" then
    return block.text:match("<img[^>]*>") ~= nil
  end
  return false
end

local function get_block_text(block)
  if block.t == "Para" or block.t == "Plain" then
    return pandoc.utils.stringify(block)
  end
  return ""
end

function Pandoc(doc)
  local blocks = doc.blocks
  local changes_made = false

  -- Look for pattern: Para (no period) → Image → Para/BlockQuote (lowercase start)
  local i = 1
  while i <= #blocks - 2 do
    local prev_block = blocks[i]
    local image_block = blocks[i + 1]
    local next_block = blocks[i + 2]

    -- Extract actual content if next_block is a BlockQuote
    local next_content_block = next_block
    if next_block.t == "BlockQuote" and #next_block.content > 0 then
      next_content_block = next_block.content[1]
    end

    -- Check if this is our pattern
    if (prev_block.t == "Para" or prev_block.t == "Plain") and
       is_image_block(image_block) and
       (next_content_block.t == "Para" or next_content_block.t == "Plain") then

      local prev_text = get_block_text(prev_block)
      local next_text = get_block_text(next_content_block)

      -- Check if previous paragraph doesn't end with sentence
      -- and next paragraph starts lowercase (continuation)
      if not ends_with_sentence(prev_text) and
         starts_lowercase(next_text) then

        -- Merge the split paragraphs
        local merged_content = {}
        for _, inline in ipairs(prev_block.content) do
          table.insert(merged_content, inline)
        end

        -- Add space between the parts
        table.insert(merged_content, pandoc.Space())

        -- Get content from next_content_block (might be inside BlockQuote)
        for _, inline in ipairs(next_content_block.content) do
          table.insert(merged_content, inline)
        end

        -- Create merged paragraph
        local merged_para = pandoc.Para(merged_content)

        -- Replace blocks: image first, then merged paragraph
        blocks[i] = image_block
        blocks[i + 1] = merged_para
        table.remove(blocks, i + 2)  -- Remove old next_block (BlockQuote or Para)

        changes_made = true

        -- Don't increment i, check this position again
        goto continue
      end
    end

    i = i + 1
    ::continue::
  end

  return pandoc.Pandoc(blocks, doc.meta)
end
