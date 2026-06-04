local class = require("class")
local combinators = require("combinators")

--- @class BinaryExpression: class, Ast
--- @field left Expression
--- @field operator Token
--- @field right Expression
local BinaryExpression = class:extend("BinaryExpression")

function BinaryExpression:init(left, operator, right)
    self.left = left
    self.operator = operator
    self.right = right
end

--- @class PrefixExpression: class, Ast
--- @field operator Token
--- @field operand Expression
local PrefixExpression = class:extend("PrefixExpression")

function PrefixExpression:init(operator, operand)
    self.operator = operator
    self.operand = operand
end

--- @class PostfixExpression: class, Ast
--- @field operand Expression
--- @field operator Token
local PostfixExpression = class:extend("PostfixExpression")

function PostfixExpression:init(operand, operator)
    self.operand = operand
    self.operator = operator
end

--- @class Precedences 
--- An input structure to describe the precedences of tokens and the expression types they belong to.
--- A precedence level is defined as a table containing a list of tokens, the expression type, and their associativity for binary expression.
--- A precedence level can also be a mapping of tokens to parsers, in which case they will be treated as postfix operators, and the parser's `parse` method will be called with the expression that is a part of it.
--- Precedences must be ordered from lowest precedence to highest. For example, `*` has higher precedence than `+`, so it should be defined below `+`.
--- `literal` is the bottom-most precedence. It should be defined as an `either` of literal values and an identifier.
--- @field literal Parser
--- @field [integer] [Token[], "prefix" | "binary" | "postfix", "left" | "right"] | [table<Token, Parser>]

--- Generates the binding power mappings for the given token precedences
--- @param precedences Precedences
--- @return table<Token, integer> prefix, table<Token, [integer, integer]> binary, table<Token, integer> postfix
local function generateBindingPower(precedences)
    local prefix, binary, postfix = {}, {}, {}
    
    local currentPrecedence = 1
    for _, precedence in ipairs(precedences) do
        if #precedence == 0 then
            -- Special expressions are always treated as postfix expressions, since they technically are ones that just contain more expressions
            for token in pairs(precedence) do
                postfix[token] = currentPrecedence
            end
            currentPrecedence = currentPrecedence + 1
        else
            local exprKind = precedence[2]
            local associativity = precedence[3]

            if exprKind == "prefix" then
                for _, token in ipairs(precedence[1]) do
                    prefix[token] = currentPrecedence
                end
                currentPrecedence = currentPrecedence + 1
            elseif exprKind == "binary" then
                if associativity == "left" then
                    for _, token in ipairs(precedence[1]) do
                        binary[token] = { currentPrecedence, currentPrecedence + 1 }
                    end
                elseif associativity == "right" then
                    for _, token in ipairs(precedence[1]) do
                        binary[token] = { currentPrecedence + 1, currentPrecedence }
                    end
                else
                    error("Expected associativity 'left' or 'right' for binary precedence.")
                end
                currentPrecedence = currentPrecedence + 2
            elseif exprKind == "postfix" then
                for _, token in ipairs(precedence[1]) do
                    postfix[token] = currentPrecedence
                end
            end
        end
    end

    return prefix, binary, postfix
end

--- Creates a new expression class
--- @param precedences Precedences
--- @return Expression
local function expression(precedences)
    local parseLiteral = precedences.literal

    --- @class Expression: class, Ast
    local Expression = class:extend("Expression")

    local prefixBindingPower, BinaryBindingPower, PostfixBindingPower = generateBindingPower(precedences)

    local specialOperators = {}
    for i = 1, #precedences do
        local precedence = precedences[i]
        if #precedence == 0 then
            for token, parser in pairs(precedence) do
                specialOperators[token] = precedence
            end
        end
    end
    --- Todo: parse based on precedences using pratt parsing
    function Expression:parse(parser, bindingPower)
    end
    
    return Expression
end

return expression