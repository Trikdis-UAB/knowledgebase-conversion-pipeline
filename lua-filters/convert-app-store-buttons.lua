-- convert-app-store-buttons.lua
-- Converts app store button images to clickable links
-- Detects button images by size and position, makes them clickable

local function is_app_button_image(src)
  -- Check if image filename matches app store button patterns
  -- These images are typically small (4-12KB) and appear in sequence
  if src:match("image1[6-9]%.png") or src:match("image2[01]%.png") then
    return true
  end
  return false
end

local function get_button_link(src)
  -- Determine which button this is based on filename
  -- Pattern: image16/19 (Google Play), image17/20 (Web), image18/21 (App Store)
  if src:match("image16%.png") or src:match("image19%.png") then
    return "https://play.google.com/store/apps/details?id=lt.apps.protegus2"
  elseif src:match("image17%.png") or src:match("image20%.png") then
    return "https://www.protegus.app"
  elseif src:match("image18%.png") or src:match("image21%.png") then
    return "https://apps.apple.com/us/app/protegus-2/id1555450252"
  end
  return nil
end

function Para(el)
  -- Check if this paragraph contains a single image that's an app button
  if #el.content == 1 and el.content[1].t == "Image" then
    local img = el.content[1]
    if is_app_button_image(img.src) then
      local link = get_button_link(img.src)
      if link then
        -- Create clickable image: <a href="link"><img src="..." /></a>
        local html = string.format(
          '<a href="%s" target="_blank"><img src="%s" alt="Download Protegus2" style="height:40px; margin:5px;"></a>',
          link, img.src
        )
        return pandoc.RawBlock("html", html)
      end
    end
  end
  return el
end
