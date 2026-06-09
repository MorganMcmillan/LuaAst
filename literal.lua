local class = require("class")

--- @class Identifier: Ast
--- @field value string
local Identifier = class:extend("Identifier")

function Identifier:init(value)
    self.value = value
end

--- @param parser Parser
function Identifier:parse(parser)
    local id, type = parser:peek()
    if type ~= "identifier" then
        error("Expected identifier, got " .. type .. " '" .. id .. "'.")
    end
    parser:skip()
    return self:new(id)
end

local sub = string.sub

--- @class Number: Ast
--- @field value number
--- @field lexeme string the raw lexeme
local Number = class:extend("Number")

function Number:init(value, lexeme)
    self.value = value
    self.lexeme = lexeme
end

--- Parses a number
--- @param parser Parser
--- @return Number
function Number:parse(parser)
    local number, type = parser:peek()
    if type ~= "number" then
        error("Expected number, got " .. type .. ".")
    end
    parser:skip()
    if sub(number, 1, 2) == "0x" then
        return self:new(tonumber(sub(number, 3), 16), number)
    end
    return self:new(tonumber(number), number)
end

--- @class String: Ast
--- @field value string
local String = class:extend("String")

function String:init(value)
    self.value = value
end

--- @param parser Parser
--- @return String
function String:parse(parser)
    local string, type = parser:peek()
    if type ~= "string" then
        error("Expected string, got " .. type .. ".")
    end
    parser:skip()
    return self:new(string)
end

return {
    Identifier = Identifier,
    Number = Number,
    String = String,
}
