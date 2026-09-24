--[[
    Bash Shell Parameter Expansion
    https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Shell-Parameter-Expansion

    Set environment variables from test.env before running tests.
]]


function Meta(meta)
  -- pandoc filter which prints versions and exits
  print("\nEnvironment: pandoc " .. tostring(PANDOC_VERSION) .. ", " .. _VERSION .. ", " .. lpeg.version)
  os.exit(1)
end

dofile("reader-env-vars.lua")


local NIL = {}
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
    ["string"] = "01234567890abcdefgh",  -- value as is
    ["string:+100"] = "100",  -- if defined
    ['num>"455":+long\nlong\ntext'] = "long\nlong\ntext",  -- gt condition
    ["#string"] = 19,  -- length
    ["string#01234567890"] = "abcdefgh",  -- remove prefix
    ["string#%d+"] = "abcdefgh",  -- remove prefix using Lua pattern
    ["string%abcdefgh"] = "01234567890",  -- remove suffix
    ["string%%a+"] = "01234567890",  -- remove suffix using Lua pattern
    ["string^^"] = "01234567890ABCDEFGH",  -- upper case
    ["string/0/o"] = "o1234567890abcdefgh",  -- replace first
    ["string/%a+/<letters>"] = "01234567890<letters>",  -- replace using Lua pattern
    ["string//0/o"] = "o123456789oabcdefgh",  -- replace all
    ["string//%d/*"] = "***********abcdefgh",  -- replace all using Lua pattern
    ["var1"] = "hello",  -- variable with a numerical suffix
    ['reserved==":+":+works'] = "works",  -- literal with reserved characters
    -- arrays
    ["arr[1]"] = "456",  -- array element
    ["arr[-1]"] = "EFGHe", ["arr[-3]"] = "456",  -- negative indexing
    ["arr[-5]"] = NIL, ["arr[4]"] = NIL,  -- out of bounds
    ["arr[2]:1:2"] = "bc",  -- substring
    ["arr[4]:-100"] = "100",  -- default
    ["arr[1]:+100"] = "100",  -- if defined
    ['arr[0]=="123":+101'] = "101",  -- eq condition with literal RHS
    ['arr[1] = num:+101'] = "101",  -- eq condition
    ["#arr[0]"] = 3,  -- length
    ["#arr"] = 18,  -- array is a space-separated string
    ["arr[2]#ab"] = "cd",  -- remove prefix
    ["arr[2]%cd"] = "ab",  -- remove suffix
    ["arr[2]^"] = "Abcd",  -- upper case first letter
    ["arr[2]^^"] = "ABCD",  -- upper case
    ["arr[3],"] = "eFGHe",  -- lower case first letter
    ["arr[3],,"] = "efghe",  -- lower case
    ["arr[1]/./A"] = "A56",  -- replace using Lua pattern
    ["arr[3]//[eE]/.."] = "..FGH..",  -- replace all using Lua pattern
}

local function repr(v)
  if type(v) == "string" then
    return string.format("%q", v)
  end
  return tostring(v)
end

for expr, expected in pairs(testcases) do
    if expected == NIL then expected = nil end
    local result = replace_var(expr)
    assert(result == expected, "Expected " .. repr(expected) .. " for '" .. expr ..
                               "', got " .. repr(result))
end

print("All tests passed.")
