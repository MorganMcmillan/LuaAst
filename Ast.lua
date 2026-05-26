--- @alias Parsable<T> { parse: fun(T, Parser): T } | fun(Parser): T

--- @class Ast: class
--- @field schema (string | Parsable)[]
--- @field desugar? fun(self: Ast): Ast desugars this Ast node into another Ast node. Called by this node's parent when this is wrapped in `desugar`.
local Ast = require("class"):extend("Ast")

--- Inherits the parent class's schema by splicing it at the top of the child's schema
--- @param subclass self
function Ast:inheritSchema(subclass)
    local schema = { unpack(self.schema) }
    local subSchema = subclass.schema
    local len = #schema - 1
    for i = 1, #subSchema do
        schema[len + i] = subSchema[i]
    end
    subclass.schema = schema
end

--- Performs further processing of this Ast node once parsed
--- Can be used to perform validations or desugar the Ast
function Ast:postProcess()
    -- Kept blank for base Ast classes
end

--- (Static) Parses this ast node from a parser
--- @param parser Parser
function Ast:parse(parser)
    local node = self:create()
    local schema = self.schema
    for i = 1, #schema, 2 do
        local field, t = schema[i], schema[i + 1]
        node[field] = parser:accept(t --[[@as Parsable]])
    end
    node:postProcess()
end

return Ast
