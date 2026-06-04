--- @class Parser: class
--- @field tokens string[] the input tokens, parsed from source code
--- @field tokenTypes TokenType[] the types of each token, parralel with the `tokens` array
--- @field pos integer the current token's position
--- @field backtrackPoint integer? the point to backtrack to when needed
local Parser = require("class"):extend("Parser")

function Parser:init(tokens, tokenTypes)
    self.tokens = tokens
    self.tokenTypes = tokenTypes
    self.pos = 1
end

function Parser:isEof()
    return self.tokenTypes[self.pos] == "eof"
end

function Parser:peek()
    local pos = self.pos
    return self.tokens[pos], self.tokenTypes[pos]
end

function Parser:skip()
    self.pos = self.pos + 1
end

function Parser:next()
    local pos = self.pos
    local token, tokenType = self.tokens[pos], self.tokenTypes[pos]
    self.pos = pos + 1
    return token, tokenType
end

function Parser:setBacktrackPoint()
    self.backtrackPoint = self.pos
end

function Parser:backtrack()
    self.pos = self.backtrackPoint
end

function Parser:consume(expected)
    local token = self:peek()
    if expected ~= token then
        error("Expected '" .. expected .. "', got '" .. token .. "'.")
    end
    self:skip()
    return token
end

function Parser:isNext(token)
    local currentToken = self.tokens[self.pos]
    if currentToken == token then
        self:skip()
        return true
    end
    return false
end

---Checks if the current token is as expected, without consuming it
---@param token string
---@return boolean
function Parser:check(token)
    return self.tokens[self.pos] == token
end

--- Accepts a parsable object or function
--- @generic T
--- @param parsable Parsable<T>
--- @return T
function Parser:accept(parsable)
    local t = type(parsable)
    if t == "function" then
        return parsable(self)
    elseif t == "table" then
        return parsable:parse(self)
    else
        error("Expected parsable (function or class), got " .. t .. ".")
    end
end

return Parser