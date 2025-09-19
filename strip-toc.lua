-- strip-toc.lua
local S = pandoc.utils.stringify
local skipping = false

return {
  Blocks = function (blocks)
    local out = {}
    for _, b in ipairs(blocks) do
      if not skipping then
        if b.t == 'Header' then
          local t = S(b.content):lower():gsub('%s+',' ')
          if t == 'contents' or t == 'table of contents' then
            skipping = true -- drop this header and start skipping
          else
            table.insert(out, b)
          end
        else
          table.insert(out, b)
        end
      else
        -- while skipping, drop everything until first non-numeric header
        if b.t == 'Header' then
          local t = S(b.content)
          if not t:match('^%s*%d') then
            skipping = false
            table.insert(out, b)
          end
        end
        -- non-headers are dropped while skipping
      end
    end
    return out
  end
}