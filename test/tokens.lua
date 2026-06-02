local Lexer = require("Lexer")
local combinators = require("tokenCombinators")

local lexer = Lexer:new {
    "+",
    ",",
    "fn",
    "(",
    ")",
    "->",
    ['"'] = combinators.string('"'),
    ["'"] = combinators.string("'"),
}

local tokens, tokenTypes = lexer:lex("fn foo(a, b) -> a + b + 100")
for i, token in ipairs(tokens) do
    print(token, tokenTypes[i])
end

tokens, tokenTypes = lexer:lex('"Hello, World!", \'Mini string!\'')
for i, token in ipairs(tokens) do
    print(token, tokenTypes[i])
end
