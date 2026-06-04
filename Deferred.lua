--- @class Deferred: class
--- @field inner Parsable<any>
local Deferred = require("class"):extend("Deferred")

function Deferred:define(definition)
    self.inner = definition
end

--- @param parser Parser
--- @return any
function Deferred:parse(parser)
    return self.inner:parse(parser)
end

return Deferred