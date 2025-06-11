--[[
    Space https://github.com/jgm/pandoc/issues/7579
    Lua string utils https://gist.github.com/kgriffs/124aae3ac80eefe57199451b823c24ec
]]

local grammar = re.compile[[
    braces <- '{{' {content*} '}}'
    content <- (!'{{' !'}}' .)+ / braces
]]
local name = "([%w_]-)%[?(-?%d*)%]?"  -- VAR or VAR[0]
local patterns = {
    variable = "^"..name.."$",  -- VAR or VAR[0]
    default = "^"..name..":%-(.+)$",
    if_defined = "^"..name..":%+(.+)$",
    substring = "^"..name..":%s*(-?%d*):?%s*(-?%d*)$",
    length = "^#"..name.."$",
    prefix = "^"..name.."#(.+)$",
    suffix = "^"..name.."%%(.+)$",
    uppercase = "^"..name.."%^(%^?)$",
    lowercase = "^"..name..",(,?)$",
    replace = "^"..name.."/(/?)(.-)/(.+)$",
}

local function getenv(name, index)
    -- get environment variable by name
    -- supports space separated arrays
    local val = os.getenv(name)
    if not val then return end

    if not index or index == '' then return val end
    index = math.tointeger(index)
    assert(index, "index is not an integer")

    local i = 0
    for item in val:gmatch("%S+") do
        if i == index then return item end
        i = i + 1
    end
end

local function Var_default(name, index, default)
    -- Default value
    local val = getenv(name, index)
    if not val then return default end
    return val
end

local function Var_if_defined(name, index, value)
    -- Return a specified value if a variable is defined
    if getenv(name, index) then return value end
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

function replace_var(expr)
    -- Match and replace a single template field

    -- Default value (!! should go earlier than a substring match)
    local name, idx, default = expr:match(patterns.default)
    if name then return Var_default(name, idx, default) end
    -- Return a specified value if a variable is defined
    local name, idx, value = expr:match(patterns.if_defined)
    if name then return Var_if_defined(name, idx, value) end
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
end

function replace_vars(text)
    -- Recursively replace all template fields in a string
    local function replace_recursive(text)
        local expr = re.gsub(text, grammar, replace_recursive)
        return replace_var(expr) or ("{{!!" .. expr .. "}}")
    end
    return re.gsub(text, grammar, replace_recursive)
end

function Reader(input, reader_options)
    -- input is a table of objects with attributes .name and .text
    a = os.clock()
    input = replace_vars(tostring(input))
    print("Variables resolved in " .. os.clock() - a .. "s")
    return pandoc.read(input, "markdown", reader_options)
end
