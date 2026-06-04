local inspect = require("inspect")

--- Generates the binding power mappings for the given token precedences
--- @param precedences Precedences
--- @return table<Token, integer> prefix, table<Token, [integer, integer]> binary, table<Token, integer> postfix
local function generateBindingPower(precedences)
    local prefix, binary, postfix = {}, {}, {}
    
    local currentPrecedence = 1
    for _, precedence in ipairs(precedences) do
        if #precedence == 0 then
            -- Special expressions are always treated as postfix expressions, since they technically are ones that just contain more expressions
            for token in pairs(precedence) do
                postfix[token] = currentPrecedence
            end
            currentPrecedence = currentPrecedence + 1
        else
            local exprKind = precedence[2]
            local associativity = precedence[3]

            if exprKind == "prefix" then
                for _, token in ipairs(precedence[1]) do
                    prefix[token] = currentPrecedence
                end
                currentPrecedence = currentPrecedence + 1
            elseif exprKind == "binary" then
                if associativity == "left" then
                    for _, token in ipairs(precedence[1]) do
                        binary[token] = { currentPrecedence, currentPrecedence + 1 }
                    end
                elseif associativity == "right" then
                    for _, token in ipairs(precedence[1]) do
                        binary[token] = { currentPrecedence + 1, currentPrecedence }
                    end
                else
                    error("Expected associativity 'left' or 'right' for binary precedence.")
                end
                currentPrecedence = currentPrecedence + 2
            elseif exprKind == "postfix" then
                for _, token in ipairs(precedence[1]) do
                    postfix[token] = currentPrecedence
                end
            end
        end
    end

    return prefix, binary, postfix
end

--- @type Precedences
local precedences = {
    literal = "foo",
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
	{['('] = "FunctionCall", ['['] = "Subscript", ['.'] = "Field", [':'] = "MethodCall"},
}

local prefix, binary, postfix = generateBindingPower(precedences)
print(inspect(prefix))
print(inspect(binary))
print(inspect(postfix))