--[[
Bold List Titles Filter

Automatically bolds short standalone paragraphs (≤5 words) that immediately precede
bullet lists in the Features section or similar contexts.

Example:
  Remote control              → **Remote control**

  - Item 1                      - Item 1
  - Item 2                      - Item 2

This creates visual hierarchy for list section titles without requiring manual formatting.
]]

function Pandoc(doc)
  local blocks = doc.blocks
  local modified = false

  -- Track if we're in a section where list titles should be bolded
  local in_features_section = false

  for i = 1, #blocks do
    local block = blocks[i]

    -- Track when we enter/exit Features-like sections
    if block.t == "Header" then
      local heading_text = pandoc.utils.stringify(block.content):lower()
      -- Check if this is a Features-type section
      if heading_text:match("feature") or
         heading_text:match("description") or
         heading_text:match("specification") then
        in_features_section = true
      -- Reset when entering major sections
      elseif block.level <= 2 then
        in_features_section = false
      end
    end

    -- Only process paragraphs in relevant sections
    if in_features_section and block.t == "Para" and i < #blocks then
      -- Check if next block is a BulletList
      local next_block = blocks[i + 1]

      if next_block and next_block.t == "BulletList" then
        -- Get text content of this paragraph
        local text = pandoc.utils.stringify(block.content)

        -- Count words (split on whitespace)
        local word_count = 0
        for _ in text:gmatch("%S+") do
          word_count = word_count + 1
        end

        -- If 5 words or less, and not already all bold, make it bold
        if word_count > 0 and word_count <= 5 then
          -- Check if already bold (all content is Strong)
          local already_bold = true
          if #block.content == 1 and block.content[1].t == "Strong" then
            -- Already bold
            already_bold = true
          elseif #block.content > 1 then
            -- Check if all inline content is strong
            already_bold = true
            for _, inline in ipairs(block.content) do
              if inline.t ~= "Strong" and inline.t ~= "Space" then
                already_bold = false
                break
              end
            end
          else
            already_bold = false
          end

          -- If not already bold, make it bold
          if not already_bold then
            blocks[i] = pandoc.Para({pandoc.Strong(block.content)})
            modified = true
          end
        end
      end
    end
  end

  if modified then
    doc.blocks = blocks
  end

  return doc
end
