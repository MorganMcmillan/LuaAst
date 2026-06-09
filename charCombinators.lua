local char = string.char
local sub = string.sub
local concat = table.concat
local charSets = require("charSets")
local digit = charSets.digit
local hexDigit = charSets.hexDigit

local charCombinators = {}

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


--- Lexes a string, processing any escape sequences and returning it without any quotes
--- @param endChar char
--- @param escapeMappings? table<string, string|fun(lexer: Lexer): string>
--- @return fun(lexer: Lexer): string, string
function charCombinators.string(endChar, escapeMappings)
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

        lexer:skip() -- quote
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
                    stringPieces[#stringPieces + 1] = char(tonumber(lexer:takeWhile(digit)) --[[@as integer]])
                else
                    error("Unexpected escape character '" .. c .. "'.")
                end
            end
            -- TODO:
            stringPieces[#stringPieces + 1] = lexer:takeUntil(stopChars)
        end
        lexer:skip()
        return concat(stringPieces), "string"
    end
end

--- Lexes a string with a single character.
--- @param endChar char
--- @param escapeMappings? table<string, string|fun(lexer: Lexer): string>
function charCombinators.singleCharString(endChar, escapeMappings)
    escapeMappings = escapeMappings or defaultEscapeMappings

    return function(lexer)
        lexer:skip()
        local c = lexer:takeUntil({ [endChar] = true })
        lexer:skip()
        -- TODO: fix to use lexer instead of raw string
        if sub(c, 1, 1) == '\\' then
            local escaped = sub(c, 2, 2)
            c = escapeMappings[escaped]
        end
        return c, "char"
    end
end

--- Skips the first character in a token sequence and then concatenates whatever the next combinator returns
--- @param combinator fun(lexer: Lexer): string, string
--- @return fun(lexer: Lexer): string, string
function charCombinators.skipFirstAndThen(combinator)
    return function(lexer)
        local first = lexer:next()
        local rest, tt = combinator(lexer)
        return first .. rest, tt
    end
end

--- Takes characters while they are inside a character set
--- @param predicate Set<char>
--- @return fun(lexer: Lexer): string, string
function charCombinators.takeWhile(predicate)
    return function(lexer)
        local result = lexer:takeWhile(predicate)
        return result, "punctuation"
    end
end

return charCombinators
