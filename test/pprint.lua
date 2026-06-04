local function getIndent(indent)
    return string.rep("  ", indent)
end

local function repr(value, indent)
    indent = indent or 0
    if type(value) == "table" then
        local out = {}
        out[#out+1] = "{\n"
        indent = indent + 1
        for k, v in pairs(value) do
            out[#out + 1] = getIndent(indent) .. k .. " = " .. repr(v, indent) .. ",\n"
        end
        indent = indent - 1
        out[#out+1] = getIndent(indent) .. "}"
        return table.concat(out)
    else
        return tostring(value)
    end
end

return function (value)
    print(repr(value))
end