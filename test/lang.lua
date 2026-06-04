local pprint = require("test.pprint")
local Ast = require("Ast")
local cmb = require("combinators")
local Deferred = require("Deferred")
local expression = require("expression")

local ExpressionDeferred = Deferred:create()

local Function = Ast:extend("Function")

Function.schema = {
    starter = "function",
    "name",
    cmb.identifier,
    "args",
    cmb.parenthesizedList(cmb.identifier),
    "body",
    cmb.after("{", cmb.repeatedUntil(ExpressionDeferred, cmb.token "}"))
}

local FunctionCall = Ast:extend("FunctionCall")

FunctionCall.schema = {
    starter = "(",
    "arguments",
    cmb.commaSeparated(ExprDeferred, ")")
}

local Subscript = Ast:extend("Subscript")

Subscript.schema = {
    starter = "[",
    "index",
    cmb.before(ExprDeferred, "]")
}

local Field = Ast:extend("Field")

Field.schema = {
    starter = ".",
    "name",
    cmb.identifier
}

local MethodCall = Ast:extend("MethodCall")

MethodCall.schema = {
    starter = ":",
    "method",
    cmb.identifier,
    "arguments",
    cmb.parenthesizedList(ExpressionDeferred)
}

local Literal = cmb.either {
    cmb.number,
    cmb.string,
    cmb.identifier,
    cmb.surrounded("(", ExpressionDeferred, ")"),
    cmb.after("[", cmb.commaSeparated(ExpressionDeferred, "]")),
}

local Expression = expression {
    literal = Literal,
    { { 'or' },                             "binary",          "left" },
    { { 'and' },                            "binary",          "left" },
    { { '==', '~=', '<', '<=', '>', '>=' }, "binary",          "left" },
    { { '|' },                              "binary",          "left" },
    { { '&' },                              "binary",          "left" },
    { { '<<', '>>' },                       "binary",          "left" },
    { { '..' },                             "binary",          "right" },
    { { '+', '-' },                         "binary",          "left" },
    { { '*', '/', '%' },                    "binary",          "left" },
    { { '-', '#' },                         "prefix",          "left" },
    { { '^' },                              "binary",          "right" },
    { ['('] = FunctionCall,                 ['['] = Subscript, ['.'] = Field, [':'] = MethodCall },
}

ExpressionDeferred:define(Expression)

local Lexer = require("Lexer")
local Parser = require("Parser")
local tcmb = require("tokenCombinators")

local lexer = Lexer:new {
    "+",
    "-",
    "*",
    "/",
    "%",
    "^",
    "&",
    "|",
    "^",
    "==",
    "~=",
    "<",
    "<=",
    ">",
    ">=",
    "<<",
    ">>",
    "#",
    "..",
    "and",
    "or",
    "(",
    ")",
    "[",
    "]",
    "{",
    "}",
    ".",
    ":",
    ",",
    ['"'] = tcmb.string('"'),
    ["'"] = tcmb.string("'"),
    "function"
}

local input = [[function foo(a, b, c) {
    a + b * c
    a / 100
}

function nop() {}]]

local t, tt = lexer:lex(input)
for i = 1, #t do
    print(t[i], tt[i])
end
local parser = Parser:new(t, tt)

local result = parser:accept(cmb.repeatedUntil(Function, cmb.eof))
pprint(result)
