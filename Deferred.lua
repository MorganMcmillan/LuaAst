--- @class Deferred: class
--- @field inner Parsable<any>
--- Used to forward-declare a parser.
local Deferred = require("class"):extend("Deferred")

--- Defines the inner value of this deferred parser.
function Deferred:define(definition)
    self.inner = definition
end

--- @param parser Parser
--- @return any
function Deferred:parse(parser)
    return parser:accept(self.inner)
end

return Deferred
