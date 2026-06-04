local Lexer = require("Lexer")
local Parser = require("Parser")

--- A facade for tokenizing input text and parsing it into an AST.
--- @param input string The input text to parse.
--- @param tokens { [integer]: string, [string]: true | fun(self): string } The tokens to use for parsing.
--- @param topLevel Parsable The top-level parser to use. This should ideally consume the entire input, including the ending eof token.
local function parse(input, tokens, topLevel)
    local lexer = Lexer:new(tokens)
    local parser = Parser:new(lexer:lex(input))
    return parser:accept(topLevel)
end

return {
    parse = parse,
    tokenCombinators = require("tokenCombinators"),
    charCombinators = require("charCombinators"),
    charSets = require("charSets"),
    Ast = require("Ast"),
    Deferred = require("Deferred"),
    expression = require("expression"),
}
