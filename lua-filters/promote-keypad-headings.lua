local TARGET_CLASS = 'keypad-subheading'

local function remove_class(header)
  local classes = header.attr.classes or {}
  local filtered = {}
  for _, cls in ipairs(classes) do
    if cls ~= TARGET_CLASS then
      table.insert(filtered, cls)
    end
  end
  header.attr.classes = filtered
end

return {
  {
    Header = function(header)
      local classes = header.attr and header.attr.classes
      if not classes or #classes == 0 then
        return nil
      end
      for _, cls in ipairs(classes) do
        if cls == TARGET_CLASS then
          header.level = math.max(3, header.level)
          remove_class(header)
          return header
        end
      end
      return nil
    end
  }
}
