local sub = string.sub

--- Converts a string of characters into a set
--- @param s string
--- @return Set<char>
local function makeCharSet(s)
    local set = {}
    for i = 1, #s do
        set[sub(s, i, i)] = true
    end
    return set
end

local charSets = {}

charSets.ws_nl = makeCharSet " \t\r\n"
charSets.whitespace = makeCharSet " \t"
charSets.newline = makeCharSet "\r\n"

charSets.sIdentStarter = "aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ_"
charSets.identStarter = makeCharSet(sIdentStarter)
charSets.ident = makeCharSet(sIdentStarter .. "1234567890")

charSets.digitStarter = makeCharSet "123456789"
charSets.digit = makeCharSet "0123456789"
charSets.hexDigit = makeCharSet "0123456789aAbBcCdDeEfF"

charSets.operatorsWithEquals = makeCharSet "=<>~"
charSets.singleCharTokens = makeCharSet "+-*/%^()[]{};:,#"

return charSets
