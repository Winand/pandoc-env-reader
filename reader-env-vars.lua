--[[
    Space https://github.com/jgm/pandoc/issues/7579
    Lua string utils https://gist.github.com/kgriffs/124aae3ac80eefe57199451b823c24ec
]]

local patterns = {
    default = "^([%w_]-):%-(.+)$",
    if_defined = "^([%w_]-):%+(.+)$",
    substring = "^([%w_]-):%s*(-?%d*):?%s*(-?%d*)$",
    length = "^#([%w_]-)$",
    prefix = "^([%w_]-)#(.+)$",
    suffix = "^([%w_]-)%%(.+)$",
    uppercase = "^([%w_]-)%^(%^?)$",
    lowercase = "^([%w_]-),(,?)$",
    replace = "^([%w_]-)/(/?)(.-)/(.+)$",
}

local function Var_default(name, default)
    -- Default value
    local val = os.getenv(name)
    if not val then return default end
    return val
end

local function Var_if_defined(name, value)
    -- Return a specified value if a variable is defined
    if os.getenv(name) then return value end
    return ""
end

local function Var_substring(name, offset, length)
    -- Substring Expansion
    -- https://unix.stackexchange.com/q/144298
    local val = os.getenv(name)
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

local function Var_length(name)
    -- Length of a variable value
    local val = os.getenv(name)
    if not val then return 0 end
    return #val
end

local function Var_remove_prefix(name, prefix)
    -- Remove prefix (does not support patterns!)
    local val = os.getenv(name)
    if not val then return end
    if val:sub(1, #prefix) == prefix then
        return val:sub(#prefix + 1) end
    return val
end

local function Var_remove_suffix(name, suffix)
    -- Remove suffix (does not support patterns!)
    local val = os.getenv(name)
    if not val then return end
    if val:sub(-#suffix) == suffix then
        return val:sub(1, #val - #suffix) end
    return val
end

local function Var_uppercase(name, all)
    -- Convert first or all characters to upper case (does not support patterns!)
    local val = os.getenv(name)
    if not val then return end
    if all and all ~= "" then return val:upper() end
    return val:sub(1, 1):upper() .. val:sub(2)
end

local function Var_lowercase(name, all)
    -- Convert first or all characters to lower case (does not support patterns!)
    local val = os.getenv(name)
    if not val then return end
    if all and all ~= "" then return val:lower() end
    return val:sub(1, 1):lower() .. val:sub(2)
end

local function Var_replace(name, old, new, all)
    -- Replace substring
    local val = os.getenv(name)
    if not val then return end
    if all and all ~= "" then return val:gsub(old, new) end
    return val:gsub(old, new, 1)
end

function replace_var(expr)
    -- Match and replace a single template field

    -- Default value (!! should go earlier than a substring match)
    local name, default = expr:match(patterns.default)
    if name then return Var_default(name, default) end
    -- Return a specified value if a variable is defined
    local name, default = expr:match(patterns.if_defined)
    if name then return Var_if_defined(name, default) end
    -- Substring Expansion
    local name, offset, length = expr:match(patterns.substring)
    if name then return Var_substring(name, offset, length) end
    -- Variable length
    local name = expr:match(patterns.length)
    if name then return Var_length(name) end
    -- Remove prefix
    local name, prefix = expr:match(patterns.prefix)
    if name then return Var_remove_prefix(name, prefix) end
    -- Remove suffix
    local name, suffix = expr:match(patterns.suffix)
    if name then return Var_remove_suffix(name, suffix) end
    -- Upper case
    local name, all = expr:match(patterns.uppercase)
    if name then return Var_uppercase(name, all) end
    -- Lower case
    local name, all = expr:match(patterns.lowercase)
    if name then return Var_lowercase(name, all) end
    -- Substring replacement
    local name, all, old, new = expr:match(patterns.replace)
    if name then return Var_replace(name, old, new, all) end

    return os.getenv(expr)  -- expression is a variable name
end

local function replace_vars(text)
    -- Replace all template fields in a string
    return text:gsub("{{(.-)}}", function(expr)
        return replace_var(expr) or ("{{!!" .. expr .. "}}")
    end)
end

function Reader(input, reader_options)
    -- input is a table of objects with attributes .name and .text
    input = replace_vars(tostring(input))
    return pandoc.read(input, "markdown", reader_options)
end
