-- remove-unwanted-blockquotes.lua
-- Remove blockquotes that are just plain text or notes, not actual citations

function BlockQuote(blockquote)
  -- Check if this blockquote contains text that should not be quoted
  local content = pandoc.utils.stringify(blockquote.content)

  -- Remove blockquotes that contain notes about control panels, manufacturers, etc.
  if content:match("Control panels directly controlled") or
     content:match("Other manufacturers") or
     content:match("Underlined") or
     content:match("PARADOX security panels") then

    -- Return the content without blockquote formatting
    return blockquote.content
  end

  -- For other blockquotes, keep them as-is (they might be actual citations)
  return blockquote
end