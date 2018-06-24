core = {}

function core.global_exists(name)
	return false
end

dofile('/home/joachim/minetest/builtin/common/vector.lua')
dofile('/home/joachim/minetest/builtin/common/misc_helpers.lua')
dofile('/home/joachim/minetest/mods/techpack/safer_lua/scanner.lua')

code = [[
-- GOOD
a = 1
a = a + 1
print(a)
foo(a)

-- BAD
_G.print(()
t = {}
for i = 1,1000 do
]]

local function error(s)
	print("[Robbi] "..s)
end

safer_lua:check(code, "Code", error)
