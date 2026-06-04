local pprint = require("test.pprint")
local Ast = require("Ast")
local combinators = require("combinators")
local Deferred = require("Deferred")
local expression = require("expression")

local ExprDeferred = Deferred:create() --[[@as Expression]]

local Literal = combinators.either{
    combinators.identifier,
    combinators.string,
    combinators.number,
    combinators.surrounded("(", ExprDeferred, ")")
}

local FunctionCall = Ast:extend("FunctionCall")

FunctionCall.schema = {
    starter = "(",
    "arguments", combinators.commaSeparated(ExprDeferred, ")")
}

local Subscript = Ast:extend("Subscript")

Subscript.schema = {
    starter = "[",
    "index", combinators.before(ExprDeferred, "]")
}

local Field = Ast:extend("Field")

Field.schema = {
    starter = ".",
    "name", combinators.identifier
}

local MethodCall = Ast:extend("MethodCall")

MethodCall.schema = {
    starter = ":",
    "method", combinators.identifier,
    "arguments", combinators.after("(", combinators.commaSeparated(ExprDeferred, ")"))
}

local Expression = expression {
    literal = Literal,
	{{'or'}, "binary", "left"},
    {{'and'}, "binary", "left"},
	{{'==', '~=', '<', '<=', '>', '>='}, "binary", "left"},
	{{'|'}, "binary", "left"},
	{{'&'}, "binary", "left"},
	{{'<<', '>>'}, "binary", "left"},
	{{'..'}, "binary", "right"},
	{{'+', '-'}, "binary", "left"},
	{{'*', '/', '%'}, "binary", "left"},
	{{'-', '#'}, "prefix", "left"},
	{{'^'}, "binary", "right"},
	{['('] = FunctionCall, ['['] = Subscript, ['.'] = Field, [':'] = MethodCall},
}

ExprDeferred:define(Expression)

local Lexer = require("Lexer")
local Parser = require("Parser")

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
    ".",
    ":",
    ","
}

local parser = Parser:new(lexer:lex("foo.function(1 + 2)"))

local result = Expression:parse(parser)
pprint(result)