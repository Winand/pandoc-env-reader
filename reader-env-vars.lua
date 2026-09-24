--[[
    Space https://github.com/jgm/pandoc/issues/7579
    Lua string utils https://gist.github.com/kgriffs/124aae3ac80eefe57199451b823c24ec
]]

local grammar = re.compile[[
    braces <- '{{' {content*} '}}'
    content <- (!'{{' !'}}' .)+ / braces
]]
local name = "([%w_]+)%[?(-?%d*)%]?"  -- VAR or VAR[0]
local opt_name = "([%w_]*)%[?(-?%d*)%]?"  -- VAR or VAR[0]
local cmp_chars = "[=!<>~]"
local patterns = {
    variable = "^"..name.."$",  -- VAR or VAR[0]
    assign = "^"..name..'%s*(:?)=%s*"(.-)"$',
    default = "^"..name..":%-(.+)$",
    -- Condition: {{VAR="literal":+text}} (comparison with a literal)
    if_condition_lit = "^"..name..'%s*('..cmp_chars..'*)%s*"(.-)"%s*:%+(.+)$',
    -- Condition: {{VAR:+text}} (defined), {{VAR=RHS:+text}} (comparison with a variable)
    if_condition = "^"..name.."%s*("..cmp_chars.."*)%s*"..opt_name.."%s*:%+(.+)$",
    substring = "^"..name..":%s*(-?%d*):?%s*(-?%d*)$",
    length = "^#"..name.."$",
    prefix = "^"..name.."#(.+)$",
    suffix = "^"..name.."%%(.+)$",
    uppercase = "^"..name.."%^(%^?)$",
    lowercase = "^"..name..",(,?)$",
    replace = "^"..name.."/(/?)(.-)/(.+)$",
}
local env_overrides = {}

-- Comparators available to the `if_condition` / `if_not_condition`
-- conditionals. Numeric operators fall back to plain string comparison
-- when either side isn't a number, so they also work on text values.
-- Add entries here (and, if needed, new operator characters to the
-- `[=!<>]*` class above) to support more comparisons.
local function try_numeric(a, b)
    local na, nb = tonumber(a), tonumber(b)
    if na and nb then return na, nb end
    return a, b
end

local comparators = {
    ["=="]  = function(a, b) return a == b end,
    ["!="] = function(a, b) return a ~= b end,
    ["<"]  = function(a, b) local x, y = try_numeric(a, b); return x < y end,
    [">"]  = function(a, b) local x, y = try_numeric(a, b); return x > y end,
    ["<="] = function(a, b) local x, y = try_numeric(a, b); return x <= y end,
    [">="] = function(a, b) local x, y = try_numeric(a, b); return x >= y end,
}
-- Aliases for comparators
comparators["="] = comparators["=="]
comparators["~="] = comparators["!="]

local function getenv(name, index)
    -- get environment variable by name
    -- supports space separated arrays
    local val = env_overrides[name] or os.getenv(name)
    if not val then return end

    if not index or index == '' then return val end
    index = math.tointeger(index)
    assert(index, "index is not an integer")

    local i = 0
    local items = {}  -- temp table for negative indexing
    for item in val:gmatch("%S+") do
        if index < 0 then
            table.insert(items, item)
        elseif i == index then
            return item
        end
        i = i + 1
    end
    if index < 0 then return items[1 + #items + index] end
end

local function Var_default(name, index, default)
    -- Default value
    local val = getenv(name, index)
    if not val then return default end
    return val
end

local function compare(lhs, op, rhs)
    local cmp = comparators[op]
    if cmp == nil then error("Comparator '"..op.."' not supported") end
    return cmp(lhs, rhs)
end

local function Var_if_condition(name, index, op, lit, text)
    -- {{VAR:+text}}     -> text if VAR is defined, else ""
    -- {{VAR=RHS:+text}} -> text if VAR matches RHS, else ""
    local lhs_val = getenv(name, index)
    if op == "" then  -- var defined
        if lhs_val then return text end
        return ""
    end
    if compare(lhs_val, op, lit) then
        return text
    end
    return ""
end

local function Var_substring(name, index, offset, length)
    -- Substring Expansion
    -- https://unix.stackexchange.com/q/144298
    local val = getenv(name, index)
    if not val then return end

    if not offset or offset == '' then offset = 0 else offset = math.tointeger(offset) end
    assert(offset, "offset is nil")
    if not length or length == '' then length = 9999 else length = math.tointeger(length) end
    assert(length, "length is nil")

    local to
    if offset >= 0 then offset = offset + 1 end
    if length < 0 then to = #val + length else to = offset + length - 1 end
    local result = val:sub(offset, to)
    return result
end

local function Var_length(name, index)
    -- Length of a variable value
    local val = getenv(name, index)
    if not val then return 0 end
    return #val
end

local function Var_remove_prefix(name, index, prefix)
    -- Remove prefix (Lua patterns supported)
    local val = getenv(name, index)
    if not val then return end
    return val:gsub("^"..prefix, "", 1)
end

local function Var_remove_suffix(name, index, suffix)
    -- Remove suffix (Lua patterns supported)
    local val = getenv(name, index)
    if not val then return end
    return val:gsub(suffix.."$", "", 1)
end

local function Var_uppercase(name, index, all)
    -- Convert first or all characters to upper case (does not support patterns!)
    local val = getenv(name, index)
    if not val then return end
    if all and all ~= "" then return val:upper() end
    return val:sub(1, 1):upper() .. val:sub(2)
end

local function Var_lowercase(name, index, all)
    -- Convert first or all characters to lower case (does not support patterns!)
    local val = getenv(name, index)
    if not val then return end
    if all and all ~= "" then return val:lower() end
    return val:sub(1, 1):lower() .. val:sub(2)
end

local function Var_replace(name, index, old, new, all)
    -- Replace substring (Lua patterns supported)
    local val = getenv(name, index)
    if not val then return end
    if all and all ~= "" then return (val:gsub(old, new)) end
    return (val:gsub(old, new, 1))  -- parentheses force to return only the first value
end

local function Var_assign(name, value, ret)
    -- Assing a value to a variable and optionally return it
    env_overrides[name] = value
    if ret == ":" then return value end
    return ""
end

function replace_var(expr)
    -- Match and replace a single template field

    -- Default value (!! should go earlier than a substring match)
    local name, idx, default = expr:match(patterns.default)
    if name then return Var_default(name, idx, default) end
    -- Return a specified value if a var is defined or an optional
    -- comparison with variable or literal is true: {{VAR:+text}} or {{VAR=RHS:+text}}
    local name, idx, op, lit, text = expr:match(patterns.if_condition_lit)
    if name then return Var_if_condition(name, idx, op, lit, text) end
    local name, idx, op, rhs, rhs_idx, text = expr:match(patterns.if_condition)
    if (rhs) then lit = getenv(rhs, rhs_idx) end  -- resolve RHS value
    if name then return Var_if_condition(name, idx, op, lit, text) end
    -- Substring Expansion
    local name, idx, offset, length = expr:match(patterns.substring)
    if name then return Var_substring(name, idx, offset, length) end
    -- Variable length
    local name, idx = expr:match(patterns.length)
    if name then return Var_length(name, idx) end
    -- Remove prefix
    local name, idx, prefix = expr:match(patterns.prefix)
    if name then return Var_remove_prefix(name, idx, prefix) end
    -- Remove suffix
    local name, idx, suffix = expr:match(patterns.suffix)
    if name then return Var_remove_suffix(name, idx, suffix) end
    -- Upper case
    local name, idx, all = expr:match(patterns.uppercase)
    if name then return Var_uppercase(name, idx, all) end
    -- Lower case
    local name, idx, all = expr:match(patterns.lowercase)
    if name then return Var_lowercase(name, idx, all) end
    -- Substring replacement
    local name, idx, all, old, new = expr:match(patterns.replace)
    if name then return Var_replace(name, idx, old, new, all) end
    -- Expression is a variable name
    local name, idx = expr:match(patterns.variable)
    if name then return getenv(name, idx) end
    -- Set or update a variable
    local name, idx, ret, lit = expr:match(patterns.assign)
    if (name and idx == "") then return Var_assign(name, lit, ret) end
end

function replace_vars(text)
    -- Recursively replace all template fields in a string
    local function replace_recursive(text)
        local expr = re.gsub(text, grammar, replace_recursive)
        return replace_var(expr) or ("{{!!" .. expr .. "}}")
    end
    return re.gsub(text, grammar, replace_recursive)
end

Extensions = {}
local _, input_formats, _ = pandoc.system.command("pandoc", {"--list-input-formats"})
for fmt in input_formats:gmatch("[^\r\n]+") do
    Extensions[fmt] = false
end

function Reader(input, reader_options)
    -- input is a table of objects with attributes .name and .text
    local specified_format
    if #reader_options.extensions == 1 then
        specified_format = reader_options.extensions[1]
    elseif #reader_options.extensions > 1 then
        error("Exactly one format extension may be specified, but specified: " ..
              table.concat(reader_options.extensions, ", "))
    end

    local docs = {}
    for i, file in ipairs(input) do  -- ipairs iterates table elements in order
        format = specified_format or pandoc.format.from_path(file.name) or "markdown"
        local a = os.clock()
        local text = replace_vars(file.text)
        print(string.format("%d %s (%s): variables resolved in %.6fs",
                            i, file.name, format, os.clock() - a))
        table.insert(docs,
            pandoc.read(text, format, reader_options)
        )
    end

    if #docs == 1 then return docs[1] end

    local combined_doc = pandoc.Pandoc({})
    for _, doc in ipairs(docs) do
        combined_doc.blocks:extend(doc.blocks)
        for k, v in pairs(doc.meta) do
            combined_doc.meta[k] = v
        end
    end
    return combined_doc
end
