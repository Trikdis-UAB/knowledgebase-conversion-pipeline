-- convert-image-tables.lua
-- Converts tables that contain only (or mostly) images into responsive HTML grids
--
-- Problem: DOCX conversions often create tables with images in cells,
-- which don't render well on mobile and clutter the markdown source
--
-- Solution: Convert to responsive flexbox grid that stacks on mobile

local S = pandoc.utils.stringify

-- Count images in a table
local function count_images_in_table(tbl)
  local total_cells = 0
  local cells_with_images = 0

  for _, row in ipairs(tbl.head.rows or {}) do
    for _, cell in ipairs(row.cells or {}) do
      total_cells = total_cells + 1
      pandoc.walk_block(pandoc.Div(cell.contents), {
        Image = function(img)
          cells_with_images = cells_with_images + 1
        end
      })
    end
  end

  for _, tbody in ipairs(tbl.bodies or {}) do
    for _, row in ipairs(tbody.body or {}) do
      for _, cell in ipairs(row.cells or {}) do
        total_cells = total_cells + 1
        pandoc.walk_block(pandoc.Div(cell.contents), {
          Image = function(img)
            cells_with_images = cells_with_images + 1
          end
        })
      end
    end
  end

  return cells_with_images, total_cells
end

-- Extract images from table cells
local function extract_images_from_table(tbl)
  local images = {}

  -- Process header rows
  for _, row in ipairs(tbl.head.rows or {}) do
    for _, cell in ipairs(row.cells or {}) do
      pandoc.walk_block(pandoc.Div(cell.contents), {
        Image = function(img)
          table.insert(images, img)
        end
      })
    end
  end

  -- Process body rows
  for _, tbody in ipairs(tbl.bodies or {}) do
    for _, row in ipairs(tbody.body or {}) do
      for _, cell in ipairs(row.cells or {}) do
        pandoc.walk_block(pandoc.Div(cell.contents), {
          Image = function(img)
            table.insert(images, img)
          end
        })
      end
    end
  end

  return images
end

-- Create responsive image grid HTML
local function create_image_grid(images)
  local html = '<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin: 1rem 0;">\n'

  for _, img in ipairs(images) do
    local alt = img.caption and S(img.caption) or ""
    local src = img.src

    html = html .. string.format(
      '  <figure style="margin: 0;">\n' ..
      '    <img src="%s" alt="%s" style="width: 100%%; height: auto;" />\n',
      src, alt
    )

    -- Add caption if alt text exists and is substantial
    if alt and #alt > 2 then
      html = html .. string.format(
        '    <figcaption style="font-size: 0.9em; text-align: center; margin-top: 0.5rem;">%s</figcaption>\n',
        alt
      )
    end

    html = html .. '  </figure>\n'
  end

  html = html .. '</div>\n'

  return pandoc.RawBlock('html', html)
end

function Table(tbl)
  -- Count how many cells contain images
  local cells_with_images, total_cells = count_images_in_table(tbl)

  -- If the table is empty, skip it
  if total_cells == 0 then
    return tbl
  end

  -- Calculate percentage of image cells
  local image_percentage = (cells_with_images / total_cells) * 100

  -- Convert to grid if >60% of cells are images
  -- AND table has fewer than 20 cells (avoid converting large tables)
  if image_percentage > 60 and total_cells <= 20 then
    local images = extract_images_from_table(tbl)

    if #images > 0 then
      -- Convert to responsive grid
      return create_image_grid(images)
    end
  end

  -- Keep table as-is if it doesn't meet criteria
  return tbl
end
