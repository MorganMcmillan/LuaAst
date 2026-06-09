local class = require("class")

--- @class Precedences
--- @field literal Parsable
--- @field [integer] [Token[], "prefix" | "binary" | "postfix", "left" | "right"] | [table<Token, Parser>]
--- An input structure to describe the precedences of tokens and the expression types they belong to.
--- A precedence level is defined as a table containing a list of tokens, the expression type, and their associativity for binary expression.
--- A precedence level can also be a mapping of tokens to parsers, in which case they will be treated as postfix operators, and the parser's `parse` method will be called with the expression that is a part of it.
--- Precedences must be ordered from lowest precedence to highest. For example, `*` has higher precedence than `+`, so it should be defined below `+`.
--- `literal` is the bottom-most precedence. It should be defined as an `either` of literal values and an identifier.

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
--- @return Expression, PrefixExpression, BinaryExpression, PostfixExpression
local function expression(precedences)
    local literal = precedences.literal

    --- @class BinaryExpression: class, Ast
    --- @field left Expression
    --- @field operator string
    --- @field right Expression
    local BinaryExpression = class:extend("BinaryExpression")

    function BinaryExpression:init(left, operator, right)
        self.left = left
        self.operator = operator
        self.right = right
    end

    --- @class PrefixExpression: class, Ast
    --- @field operator string
    --- @field operand Expression
    local PrefixExpression = class:extend("PrefixExpression")

    function PrefixExpression:init(operator, operand)
        self.operator = operator
        self.operand = operand
    end

    --- @class PostfixExpression: class, Ast
    --- @field operand Expression
    --- @field operator string
    local PostfixExpression = class:extend("PostfixExpression")

    function PostfixExpression:init(operand, operator)
        self.operand = operand
        self.operator = operator
    end

    --- @class Expression: class, Ast
    local Expression = class:extend("Expression")

    local prefixBindingPower, binaryBindingPower, postfixBindingPower = generateBindingPower(precedences)

    local specialOperators = {}
    for i = 1, #precedences do
        local precedence = precedences[i]
        if #precedence == 0 then
            for token, parser in pairs(precedence) do
                specialOperators[token] = parser
            end
        end
    end

    --- @param parser Parser
    local function primaryExpression(parser)
        local op = parser:peek()
        local prefixBp = prefixBindingPower[op]
        if prefixBp then
            parser:next()
            local rhs = Expression:parsePrecedence(parser, prefixBp)
            return PrefixExpression:new(op, rhs)
        else
            return parser:accept(literal)
        end
    end

    --- @param parser Parser
    ---@param minBindingPower integer
    function Expression:parsePrecedence(parser, minBindingPower)
        local lhs = primaryExpression(parser)

        while true do
            local op = parser:peek()
            local postfixBp = postfixBindingPower[op]
            if postfixBp then
                if postfixBp < minBindingPower then break end

                local specialOperator = specialOperators[op]
                if specialOperator then
                    local operand = lhs
                    lhs = specialOperator:parse(parser, postfixBp)
                    lhs.operand = operand
                else
                    parser:next()
                    lhs = PostfixExpression:new(op, lhs)
                end
            else
                local binaryBp = binaryBindingPower[op]
                if binaryBp then
                    local leftBp, rightBp = binaryBp[1], binaryBp[2]
                    if leftBp < minBindingPower then break end
                    parser:next()

                    lhs = BinaryExpression:new(lhs, op, self:parsePrecedence(parser, rightBp))
                else
                    break
                end
            end
        end

        return lhs
    end

    function Expression:parse(parser)
        return self:parsePrecedence(parser, 0)
    end

    return Expression, PrefixExpression, BinaryExpression, PostfixExpression
end

return expression
