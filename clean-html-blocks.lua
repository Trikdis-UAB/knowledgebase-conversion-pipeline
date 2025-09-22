-- clean-html-blocks.lua
-- Converts raw HTML blocks with {=html} to clean HTML that MkDocs can render
-- This fixes image display issues where images appear as `<img ...>`{=html}

function RawInline(elem)
    if elem.format == "html" then
        -- Convert raw HTML inline to clean HTML
        return pandoc.RawInline("html", elem.text)
    end
    return elem
end

function RawBlock(elem)
    if elem.format == "html" then
        -- Convert raw HTML block to clean HTML
        return pandoc.RawBlock("html", elem.text)
    end
    return elem
end

-- Also handle CodeBlock elements that might contain HTML with {=html}
function CodeBlock(elem)
    if elem.text:match("{=html}") then
        -- Extract HTML content and convert to RawBlock
        local html_content = elem.text:gsub("`([^`]*)`{=html}", "%1")
        return pandoc.RawBlock("html", html_content)
    end
    return elem
end

-- Handle Code (inline) elements that might contain HTML with {=html}
function Code(elem)
    if elem.text:match("{=html}") then
        -- Extract HTML content and convert to RawInline
        local html_content = elem.text:gsub("`([^`]*)`{=html}", "%1")
        return pandoc.RawInline("html", html_content)
    end
    return elem
end