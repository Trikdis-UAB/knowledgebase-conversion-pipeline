-- convert-image-sizes.lua
-- Convert Pandoc image size attributes to HTML with CSS for MkDocs compatibility

return {
  Image = function(image)
    -- Check if image has width/height attributes
    local width = image.attributes.width
    local height = image.attributes.height

    if width or height then
      -- Create style attribute for CSS
      local style_parts = {}

      if width then
        table.insert(style_parts, "width:" .. width)
      end

      if height then
        table.insert(style_parts, "height:" .. height)
      end

      local style = table.concat(style_parts, ";")

      -- Create HTML img tag with CSS style
      local html_img = string.format(
        '<img alt="%s" src="%s" style="%s" />',
        image.caption and pandoc.utils.stringify(image.caption) or "",
        image.src,
        style
      )

      -- Return as RawInline HTML instead of Pandoc Image
      return pandoc.RawInline("html", html_img)
    end

    -- If no size attributes, return image unchanged
    return image
  end
}