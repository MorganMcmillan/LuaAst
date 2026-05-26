local char = string.char
local concat = table.concat
local charSets = require("charSets")
local digit = charSets.digit
local hexDigit = charSets.hexDigit

local tokenCombinators = {}

local defaultEscapeMappings = {
    ["\\a"] = '\a',
    ["\\b"] = '\b',
    ["\\f"] = '\f',
    ["\\r"] = '\r',
    ["\\n"] = '\n',
    ["\\\n"] = '\n',
    ["\\t"] = '\t',
    ["\\v"] = '\v',
    ["\\'"] = '\'',
    ["\\\""] = '\"',
    ---@param lexer Lexer
    ---@return string
    ["\\x"] = function(lexer)
        return char(tonumber(lexer:takeWhile(hexDigit), 16))
    end,
}


---Lexes a string, processing any escape sequences and returning it without any quotes
---@param endChar string
---@return fun(lexer: Lexer): string
function tokenCombinators.lexString(endChar, escapeMappings)
    escapeMappings = escapeMappings or defaultEscapeMappings
    local stopChars = {
        [endChar] = true,
        ['\\'] = true
    }

    return function(lexer)
        -- Takes until `endChar`
        -- When `\`: scan following characters
        -- `\'`: literal single quote
        local stringPieces = {}

        while lexer:peek() ~= endChar do
            if lexer:peek() == '\\' then
                lexer:skip()
                -- Process escape sequence
                local c = lexer:peek()
                local escapeMapping = escapeMappings[c]

                local T = type(escapeMapping)
                if T == "string" then
                    stringPieces[#stringPieces + 1] = escapeMapping
                elseif T == "function" then
                    stringPieces[#stringPieces + 1] = escapeMapping(lexer)
                elseif digit[c] then
                    -- TODO: limit the characters taken to 3
                    stringPieces[#stringPieces + 1] = char(tonumber(lexer:takeWhile(digit)))
                else
                    error("Unexpected escape character '" .. c .. "'.")
                end
            end
            -- TODO:
            stringPieces[#stringPieces + 1] = lexer:takeUntil(stopChars)
        end
        return concat(stringPieces)
    end
end

return tokenCombinators
