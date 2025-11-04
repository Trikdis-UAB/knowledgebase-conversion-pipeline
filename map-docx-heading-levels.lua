-- map-docx-heading-levels.lua
-- Maps DOCX heading styles to proper markdown levels
-- DOCX Heading 1 ("Pagrindinis") → H2
-- DOCX Heading 2 ("2-Po-Pag") → H3
-- DOCX Heading 3 ("3-po-Pag") → H4
-- This ensures the heading hierarchy matches the DOCX table of contents

function Header(el)
    -- Get the classes from the header
    local classes = el.classes or {}

    -- Check for DOCX Word style classes
    for _, class in ipairs(classes) do
        local lower_class = class:lower()

        -- DOCX Heading 1 (class "Pagrindinis") → Currently H1, should be H2
        if class == "Pagrindinis" then
            if el.level == 1 then
                el.level = 2
            end
            return el
        end

        -- DOCX Heading 2 (class "2-Po-Pag") → Currently H2, should be H3
        if lower_class == "2-po-pag" then
            if el.level == 2 then
                el.level = 3
            end
            return el
        end

        -- DOCX Heading 2 variants like "1.1-Po-pag-(nerodyti-turiny)" → demote to H3
        if lower_class:match('^%d+%.%d+-po%-pag') then
            if el.level == 2 then
                el.level = 3
            end
            return el
        end

        -- DOCX Heading 3 (class "3-po-Pag" or "3-Po-Pag") → Currently H3, should be H4
        if class == "3-po-Pag" or class == "3-Po-Pag" then
            if el.level == 3 then
                el.level = 4
            end
            return el
        end

        -- DOCX Heading 4 (class "4-po-Pag") → Currently H4, should be H5
        if class == "4-po-Pag" or class == "4-Po-Pag" then
            if el.level == 4 then
                el.level = 5
            end
            return el
        end
    end

    return el
end
