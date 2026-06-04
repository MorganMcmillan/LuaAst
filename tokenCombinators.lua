local tokenCombinators = {}

--- @param token string
function tokenCombinators.token(token)
    --- @param parser Parser
    return function(parser)
        return parser:consume(token)
    end
end

--- @param expected string
function tokenCombinators.checkToken(expected)
    --- @param parser Parser
    return function(parser)
        local token = parser:peek()
        if expected == token then
            return expected
        end
        error("Expected '" .. expected .. "', got '" .. token .. "'.")
    end
end

function tokenCombinators.eof(parser)
    local token, tt = parser:peek()
    if tt ~= "eof" then
        error("Expected EOF, got '" .. token .. "'.")
    end
    return true
end

--- Parses an identifier
--- @param parser Parser
--- @return string
function tokenCombinators.identifier(parser)
    local id, type = parser:peek()
    if type ~= "identifier" then
        error("Expected identifier, got " .. type .. ".")
    end
    parser:skip()
    return id
end

local sub = string.sub

--- @param parser Parser
function tokenCombinators.number(parser)
    local number, type = parser:peek()
    if type ~= "number" then
        error("Expected number, got " .. type .. ".")
    end
    parser:skip()
    if sub(number, 1, 2) == "0x" then
        return tonumber(sub(number, 3), 16)
    end
    return tonumber(number)
end

--- @param parser Parser
function tokenCombinators.string(parser)
    local string, type = parser:peek()
    if type ~= "string" then
        error("Expected string, got " .. type .. ".")
    end
    parser:skip()
    return {
        name = "string",
        contents = string
    }
end

---@generic T
---@param token string
---@param parsable Parsable<T>
---@return Parsable<T>
function tokenCombinators.after(token, parsable)
    --- @param parser Parser
    return function(parser)
        parser:consume(token)
        return parser:accept(parsable)
    end
end

---@generic T
---@param token string
---@param parsable Parsable<T>
---@return Parsable<T | nil>
function tokenCombinators.ifAfter(token, parsable)
    --- @param parser Parser
    return function(parser)
        if parser:isNext(token) then
            return parser:accept(parsable)
        end
    end
end

---@generic T
---@param parsable Parsable<T>
---@param token string
---@return Parsable<T>
function tokenCombinators.before(parsable, token)
    --- @param parser Parser
    return function(parser)
        local result = parser:accept(parsable)
        parser:consume(token)
        return result
    end
end

---@generic T
---@param startToken string
---@param parsable Parsable<T>
---@param endToken string
---@return Parsable<T>
function tokenCombinators.surrounded(startToken, parsable, endToken)
    --- @param parser Parser
    return function(parser)
        parser:consume(startToken)
        local result = parser:accept(parsable)
        parser:consume(endToken)
        return result
    end
end

---Parses a comma-separated list of items
---@generic T
---@param parsable Parsable<T>
---@param closing string?
---@param isTrailingCommaAllowed boolean?
---@return Parsable<T[]>
function tokenCombinators.commaSeparated(parsable, closing, isTrailingCommaAllowed)
    if closing then
        --- @param parser Parser
        return function(parser)
            local list = {}
            if not parser:isNext(closing) then
                repeat
                    if isTrailingCommaAllowed and parser:check(closing) then
                        break
                    end
                    list[#list + 1] = parser:accept(parsable)
                until not parser:isNext(",")

                parser:consume(closing)
            end

            return list
        end
    else
        --- @param parser Parser
        return function(parser)
            local list = {}
            -- Does not allow trailing commas
            repeat
                list[#list + 1] = parser:accept(parsable)
            until not parser:isNext(",")

            return list
        end
    end
end

--- Parses a parenthesized comma-separated list of `parsable`s
---@generic T
---@param parsable Parsable<T>
---@return Parsable<T[]>
function tokenCombinators.parenthesizedList(parsable)
    return tokenCombinators.after("(", tokenCombinators.commaSeparated(parsable, ")"))
end

--- Parses a brace-enclosed block of `statement`s.
--- @generic T
--- @param statement Parsable<T>
--- @return Parsable<T[]>
function tokenCombinators.braceBlock(statement)
    return tokenCombinators.after("{", tokenCombinators.repeatedUntil(statement, "}"))
end

---Repeatedly parses a parsable until it cannot anymore
---@generic T
---@param parsable Parsable<T>
---@return Parsable<T[]>
function tokenCombinators.repeatedly(parsable)
    --- @param parser Parser
    return function(parser)
        local accept = parser.accept
        local list = {}

        local ok, object = pcall(accept, parser, parsable)
        while ok do
            list[#list + 1] = object
            ok, object = pcall(accept, parser, parsable)
        end
        return list
    end
end

---Repeatedly parses a parsable until `untilParsable` suceeds parsing
---@generic T
---@param parsable Parsable<T>
---@param untilParsable Parsable
---@return Parsable<T>
function tokenCombinators.repeatedUntil(parsable, untilParsable)
    --- @param parser Parser
    return function(parser)
        -- TODO: needs testing
        local accept = parser.accept
        local list = {}

        while not pcall(accept, parser, untilParsable) do
            list[#list + 1] = accept(parser, parsable)
        end
        return list
    end
end

-- TODO: group parsables by "starter" field
--- @param parsables (Parsable | Ast)[]
function tokenCombinators.either(parsables)
    local withStarter, withoutStarter = {}, {}
    for i = 1, #parsables do
        local parsable = parsables[i]
        if type(parsable) == "table" and parsable.schema and parsable.schema.starter then
            withStarter[parsable.schema.starter] = parsable
        else
            withoutStarter[#withoutStarter + 1] = parsable
        end
    end
    --- @param parser Parser
    return function(parser)
        local token = parser:peek()
        local starterParser = withStarter[token]
        if starterParser then
            return starterParser:parse(parser)
        end

        parser:setBacktrackPoint()
        for i = 1, #withoutStarter do
            local parsable = withoutStarter[i]
            local ok, result = pcall(parser.accept, parser, parsable)
            if ok then
                return result
            end
            parser:backtrack()
        end
        -- Maybe make this error more detailed?
        -- Include parsable names?
        error("Failed to parse either option.")
    end
end

---Verifies a parsed object
---@generic T
---@param parsible Parsable<T>
---@param verifier fun(T): boolean
---@return Parsable<T>
function tokenCombinators.verify(parsible, verifier)
    --- @param parser Parser
    return function(parser)
        local object = parser:accept(parsible)
        assert(verifier(object))
        return object
    end
end

return tokenCombinators
