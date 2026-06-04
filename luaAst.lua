local Ast = require("Ast")
local cmb = require("combinators")
local Deferred = require("Deferred")

--- @class Statement: Deferred, Ast
local Statement = Deferred:create()

--- @class Expression: Deferred, Ast
local Expression = Deferred:create()

local Block = cmb.repeated(Statement)

local Parameter = cmb.either{
    cmb.identifier,
    cmb.token"..."
}

--- @alias Body Statement[]

--- @type Body
local Body = cmb.repeatedUntil(Statement, cmb.token"end")

--- @class FunctionDeclaration: Ast
--- @field name string
--- @field parameters string[]
--- @field body Statement[]
local FunctionDeclaration = Ast:extend("FunctionDeclaration")

FunctionDeclaration.schema = {
    starter = "function",
    "name", Expression,
    "parameters", cmb.after("(", cmb.commaSeparated(Parameter, ")")),
    "body", Body
}

---@class MethodDeclaration: Ast
local MethodDeclaration = Ast:extend("MethodDeclaration")

MethodDeclaration.schema = {
    starter = "function",
    "name", Expression,
    "methodName", cmb.after(":", cmb.identifier),
    "parameters", cmb.after("(", cmb.commaSeparated(Parameter, ")")),
    "body", Body
}

--- @class DoStatement: Ast
--- @field body Body
local DoStatement = Ast:extend("DoStatement")

DoStatement.schema = {
    starter = "do",
    "body", Body
}

--- @class ElseIf: Ast
local ElseIf = Ast:extend("ElseIf")

ElseIf.schema = {
    starter = "elseif",
    "condition", Expression,
    "body", Block
}

--- @class IfStatement: Ast
local IfStatement = Ast:extend("IfStatement")

IfStatement.schema = {
    starter = "if",
    "condition", Expression,
    "body", cmb.after("then", cmb.repeated(Statement))
    "elseifs", cmb.repeatedUntil(ElseIf, cmb.either{
        cmb.token"end",
        cmb.checkToken"else"
    }),
    "else", cmb.ifAfter("else", Body)
}

--- @class WhileStatement: Ast
--- @field condition Expression
--- @field body Body
local WhileStatement = Ast:extend("WhileStatement")

WhileStatement.schema = {
    starter = "while",
    "condition", Expression,
    "body", cmb.after("do", Body)
}

--- @class RepeatUntilStatement: Ast
--- @field body Body
--- @field condition Expression
local RepeatUntilStatement = Ast:extend("RepeatUntilStatement")

RepeatUntilStatement.schema = {
    starter = "repeat",
    "body", Block,
    "condition", cmb.after("until", Expression)
}

--- @class NumericFor: Ast
--- @field variable string
--- @field first number
--- @field last number
--- @field step number?
--- @field body Body
local NumericFor = Ast:extend("NumericFor")

NumericFor.schema = {
    starter = "for",
    "variable", cmb.identifier,
    "first", cmb.after("=", cmb.number),
    "last", cmb.after(",", cmb.number),
    "step", cmb.ifAfter(",", cmb.number),
    "body", cmb.after("do", Body)
}

--- @class GenericFor: Ast
--- @field variables string[]
--- @field expressions Expression[]
--- @field body Body
local GenericFor = Ast:extend("GenericFor")

GenericFor.schema = {
    starter = "for",
    "variables", cmb.commaSeparated(cmb.identifier, "in"),
    "expressions", cmb.commaSeparated(Expression, "do"),
    "body", Body
}

--- Expressions

--- @class FunctionDefinition: Ast
local FunctionDefinition = Ast:extend("FunctionDefinition")

FunctionDefinition.schema = {
    starter = "function",
    "parameters", cmb.after("(", cmb.commaSeparated(Parameter, ")")),
    "body", Body
}

--- @class TableAssignment: Ast
local TableAssignment = Ast:extend("TableAssignment")

TableAssignment.schema = {
    "name", cmb.either{
        cmb.surrounded("[", Expression, "]"),
        cmb.identifier
    },
    "value", cmb.after("=", Expression)
}

local TableField = cmb.either{
    TableAssignment,
    Expression
}

--- @class TableConstructor: Ast
--- @field fields table
local TableConstructor = Ast:extend("TableConstructor")

TableConstructor.schema = {
    starter = "{",
    "fields", cmb.commaSeparated(TableField, "}", true)
}

local ExpressionBase = Ast:extend("Expression")

function ExpressionBase:parse(parser)
    -- Parse with precedence
end

local VarList = cmb.commaSeparated(cmb.identifier)

local function isAssignable(expression)
    -- TODO:
end

local AssignList = cmb.commaSeparated(cmb.verify(Expression, isAssignable))

Expression:define(ExpressionBase)