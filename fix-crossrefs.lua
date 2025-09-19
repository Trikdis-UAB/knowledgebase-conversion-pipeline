-- fix-crossrefs.lua
local S = pandoc.utils.stringify
return {
  Para = function(p)
    local t = S(p)
    t = t:gsub("Error! Reference source not found%.", "see the referenced section")
    if t ~= S(p) then return pandoc.Para({pandoc.Str(t)}) end
  end
}