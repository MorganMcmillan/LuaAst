---@alias TokenType "number" | "string" | "identifier" | "keyword" | "punctuation" | "eof"

local sub, match = string.sub, string.match
local max = math.max

local charSets = require("charSets")
local ident = charSets.ident
local identStarter = charSets.identStarter
local digit = charSets.digit
local digitStarter = charSets.digitStarter
local hexDigit = charSets.hexDigit

--- @class Set<T>: table<T, true>
--- @alias char string
--- @alias Token string | number

-- Character sets

---@class Lexer: class
---@field input string the input source code
---@field pos integer the current input position
---@field tokens { [string]: true | fun(self): string?, TokenType? } the set of allowed tokens. Function values means that the token sequence takes control of the lexer.
---@field lookaheads { [string]: integer } the lookahead lengths for each token. These are iterated backwards to allow matching multi-character tokens.
---@field keywords Set<string>
local Lexer = require("class"):extend("Lexer")

-- Note: I may add a config table later, for things like identifiers and numbers.

---@param tokens { [integer]: string, [string]: true | fun(self): string } the allowed tokens
function Lexer:init(tokens)
    local tokenSet = {}
    local lookaheads = {}
    local keywords = {}
    for token, v in pairs(tokens) do
        -- Conform array part to
        if type(token) == "number" then -- token is in array part
            token = v --[[@as Token]]
            v = true
        end

        local c = sub(token, 1, 1)
        if match(c, "%a") then
            keywords[token] = true
        else
            local group = lookaheads[c]
            if not group then
                lookaheads[c] = #token
            else
                lookaheads[c] = max(group, #token)
            end

            tokenSet[token] = v
        end
    end

    self.tokens = tokenSet
    self.lookaheads = lookaheads
    self.keywords = keywords
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

--- Takes n characters from the input, starting at the current character.
--- Does not advance the position.
--- @param n integer the number of characters to take
--- @return string
function Lexer:take(n)
    local pos = self.pos
    return sub(self.input, pos, pos - 1)
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

--- Lexes a list of tokens.
--- This is the main function that lexes the input.
--- @param input string the input to lex
--- @return Token[] tokens, TokenType[] tokenTypes
function Lexer:lex(input)
    self.input = input
    self.pos = 1

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

--- Lexes a single token.
--- @return Token token, TokenType tokenType
function Lexer:lexToken()
    self:takeWhile(whitespace)

    local c = self:peek()

    local lookahead = self.lookaheads[c]
    if lookahead then
        for i = lookahead, 1, -1 do
            local token = self:take(i)
            local action = self.tokens[token]
            if action then
                if action == true then
                    self.pos = self.pos + i
                    return token, "punctuation"
                else
                    -- Note: action is responsible for advancing the position and returning the token's type
                    -- Disabled because returning nil is valid and doesn't add anything to the token array
                    ---@diagnostic disable-next-line: return-type-mismatch
                    return action(self)
                end
            end
        end
    elseif identStarter[c] then
        local ident = self:takeWhile(ident)
        if self.keywords[ident] then
            return ident, "keyword"
        end
        return ident, "identifier"
        -- TODO: allow adding custom numeric bases, like hex, binary, or other
        -- TODO: lex numbers with decimal points
        -- Perhaps allow a custom function to be used, through a config table.
    elseif c == "0" then
        if self:peekAhead(2) == "x" then
            self.pos = self.pos + 2
            local hex = self:takeWhile(hexDigit)
            return assert(tonumber(hex, 16)), "number"
        elseif match(c, "[%d]") then
            return assert(tonumber(self:takeWhile(digit))), "number"
        end
    elseif digitStarter[c] then
        return self:takeWhile(digit), "number"
    end
    error("Unexpected character '" .. c .. "'.")
end

return Lexer
