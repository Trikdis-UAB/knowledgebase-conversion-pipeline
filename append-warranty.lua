--[[
Append Warranty Sections Filter

This filter runs LAST in the pipeline to append warranty/safety requirement
sections to the end of the document. Content was preserved by preserve-warranty.lua
and stored in document metadata.

The warranty section is added as a final H2 chapter at the bottom of the document.
]]

function Pandoc(doc)
  -- Check if we have preserved warranty content
  if not doc.meta['warranty_blocks'] then
    -- No warranty content found, return doc unchanged
    return doc
  end

  -- Get warranty heading text and content from metadata
  local heading_text = pandoc.utils.stringify(doc.meta['warranty_heading_text'])
  local warranty_blocks = doc.meta['warranty_blocks']

  -- Add blank line before warranty section
  table.insert(doc.blocks, pandoc.Para{})

  -- Add warranty heading as H2
  table.insert(doc.blocks, pandoc.Header(2, {pandoc.Str(heading_text)}))

  -- Add warranty content blocks
  if warranty_blocks then
    -- MetaBlocks is iterable like a list
    for _, block in ipairs(warranty_blocks) do
      table.insert(doc.blocks, block)
    end
  end

  -- Clean up metadata (optional - keeps output clean)
  doc.meta['warranty_heading_text'] = nil
  doc.meta['warranty_heading_level'] = nil
  doc.meta['warranty_blocks'] = nil

  return doc
end

return {
  {Pandoc = Pandoc}
}
