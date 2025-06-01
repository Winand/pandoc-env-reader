--[[
    Bash Shell Parameter Expansion
    https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Shell-Parameter-Expansion

    Set environment variables before running tests:
    $env:string="01234567890abcdefgh"
]]

dofile("reader-env-vars.lua")


local testcases = {
    -- substring
    ["string:7"] = "7890abcdefgh",
    ["string:7:0"] = "",
    ["string:7:2"] = "78",
    ["string:7:-2"] = "7890abcdef",
    ["string: -7"] = "bcdefgh",  -- overlaps with default pattern if space not included
    ["string: -7:0"] = "",
    ["string: -7:2"] = "bc",
    ["string: -7:-2"] = "bcdef",
    -- default
    ["unset:-100"] = "100",
    ["unset:-default"] = "default",
    ["unset:-with space"] = "with space",
    -- other cases
    ["string:+100"] = "100",  -- if defined
    ["#string"] = 19,  -- length
    ["string#01234567890"] = "abcdefgh",  -- remove prefix
    ["string%abcdefgh"] = "01234567890",  -- remove suffix
    ["string^^"] = "01234567890ABCDEFGH",  -- upper case
    ["string/0/o"] = "o1234567890abcdefgh",  -- replace first
    ["string//0/o"] = "o123456789oabcdefgh",  -- replace all
}

for expr, expected in pairs(testcases) do
    local result = replace_var(expr)
    assert(result == expected, "Expected '" .. expected .. "' for '" .. expr .. "', got '" .. result .. "'")
end

print("All tests passed.")
