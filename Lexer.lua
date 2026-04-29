---@alias TokenType "number" | "string" | "identifier" | "punctuation" | "eof"

local char, sub, concat = string.char, string.sub, table.concat

-- Character sets

local function makeCharSet(s)
    local set = {}
    for i = 1, #s do
        set[sub(s, i, i)] = true
    end
    return set
end

local ws_nl = makeCharSet" \t\r\n"
local whitespace = " \t"
local newline = makeCharSet"\r\n"

local sIdentStarter = "aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ_"
local identStarter = makeCharSet(sIdentStarter)
local ident = makeCharSet(sIdentStarter .. "1234567890")

local digitStarter = makeCharSet"123456789"
local digit = makeCharSet"0123456789"
local hexDigit = makeCharSet"0123456789aAbBcCdDeEfF"

local operatorsWithEquals = makeCharSet"=<>~"
local singleCharTokens = makeCharSet"+-*/%^()[]{};:,#"

---@class Lexer: class
---@field input string the input source code
---@field pos integer the current input position
local Lexer = require("class"):extend("Lexer")

---@param input string
function Lexer:init(input)
    self.input = input
    self.pos = 1
end

function Lexer:peek()
    return sub(self.input, self.pos, self.pos)
end

function Lexer:peekAhead(by)
    local pos = self.pos + by
    return sub(self.input, pos, pos)
end

function Lexer:next()
    local char = sub(self.input, self.pos, self.pos)
    self.pos = self.pos + 1
    return char
end

---Skips the current character
function Lexer:skip()
    self.pos = self.pos + 1
end

---Takes characters while they are in a set. The position is then set *after* the end of the taken characters.
---@param set { [string]: true } the set of characters
---@return string
function Lexer:takeWhile(set)
    local start = self.pos
    while set[self:peek()] do
        self:skip()
    end
    return sub(self.input, start, self.pos - 1)
end

---Takes characters while they are in a set
---@param set { [string]: true } the set of characters
---@return string
function Lexer:takeUntil(set)
    local start = self.pos
    while not set[self:peek()] do
        self:skip()
    end
    return sub(self.input, start, self.pos - 1)
end

---Lexes a list of tokens
---@return string[] tokens, TokenType[] tokenTypes
function Lexer:lex()
    local tokens, tokenTypes = {}, {}
    local n = 1
    while self:notEof() do
        tokens[n], tokenTypes[n] = self:lexToken()
        n = n + 1
    end
    tokens[n], tokenTypes[n] = "", "eof"
    return tokens, tokenTypes
end

function Lexer:notEof()
    return self.pos <= #self.input
end

---Lexes a single token
---@return string token, TokenType tokenType
function Lexer:lexToken()
    -- Skip whitespace
    self:takeWhile(whitespace)

    local c = self:peek()

    -- Lex token
    if identStarter[c] then
        -- Lex identifier
        -- Note: keywords and identifiers are lexed the same
        return self:takeWhile(ident), "identifier"
    elseif digitStarter[c] then
        -- Lex number
        return self:takeWhile(digit), "number"
    elseif c == '0' then
        -- Lex number with base or 0
        if self:peek() == 'x' then
            self:skip()
            self:skip()

            local hexDigits = self:takeWhile(hexDigit)
            if #hexDigits == 0 then
                error("Expected a hex digit sequence, got empty.")
            end

            return "0x" .. hexDigits, "number"
        else
            return "0", "number"
        end
    elseif c == '"' or c == '\'' then
        -- Lex string
        return self:lexString(c), "string"
        
    -- Lex punctuation characters
    
    elseif c == '-' then
        self:skip()
        local next = self:peek()
        if next == '-' then
            self:skip()
            -- Check for multi line comment
            if self:peek() == '[' and self:peekAhead(1) == '[' then
                self:takeUntilSequence("]]")
            end
            -- Skip single line comment
            self:takeUntil(newline)
        else
            return '-', "punctuation"
        end
    elseif c == '.' then
        self:skip()
        if self:peek() == '.' then
            self:skip()
            if self:peek() == '.' then
                self:skip()
                return '...', "punctuation"
            else
                return '..', "punctuation"
            end
        else
            return c, "punctuation"
        end
    elseif operatorsWithEquals[c] then
        self:skip()
        if self:peek() == '=' then
            self:skip()
            return c .. '=', "punctuation"
        else
            return c, "punctuation"
        end
    elseif singleCharTokens[c] then
        self:skip()
        return c, "punctuation"
    end
    error("Unexpected character '" .. c .. "'.")
end

local escapeMappings = {
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
    ["\\x"] = function (lexer)
        return char(tonumber(lexer:takeWhile(hexDigit), 16))
    end,
}

---Lexes a string, processing any escape sequences and returning it without any quotes
---@param endChar string
---@return string
function Lexer:lexString(endChar)
    -- Takes until `endChar`
    -- When `\`: scan following characters
    -- `\'`: literal single quote
    local stringPieces = {}
    local foo = {
        [endChar] = true,
        ['\\'] = true
    }

    while self:peek() ~= endChar do
        if self:peek() == '\\' then
            self:skip()
            -- Process escape sequence
            local c = self:peek()
            local escapeMapping = escapeMappings[c]
            local T = type(escapeMapping)
            if T == "string" then
                stringPieces[#stringPieces+1] = escapeMapping
            elseif T == "function" then
                stringPieces[#stringPieces+1] = escapeMapping(self)
            elseif digit[c] then
                -- TODO: limit the characters taken to 3
                stringPieces[#stringPieces+1] = char(tonumber(self:takeWhile(digit)))
            else
                error("Unexpected escape character '" .. c .. "'.")
            end
        end
        -- TODO:
        stringPieces[#stringPieces+1] = self:takeUntil(foo)
    end
    return concat(stringPieces)
end

return Lexer