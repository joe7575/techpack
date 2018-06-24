core = {}

function core.global_exists(name)
	return false
end

dofile('/home/joachim/minetest/builtin/common/vector.lua')
dofile('/home/joachim/minetest/builtin/common/misc_helpers.lua')

safer_lua = {}
dofile('/home/joachim/minetest/mods/techpack/safer_lua/store.lua')
dofile('/home/joachim/minetest/mods/techpack/safer_lua/scanner.lua')
dofile('/home/joachim/minetest/mods/techpack/safer_lua/environ.lua')

--local Cache = {}
--local key = minetest.pos_to_hash(pos)
--code = Cache[key]

local function foo(self, val)
	_G = self._G
	print("Hallo", val)
end	

local function error(pos, s)
	print("[Test] "..s)
end

local init = "init = 5"
local loop = [[
  $foo("hallo")
  S.foo("hallo")
  --S._G.print("Fehler")
  $foo(math.floor(5.5))
  $foo("Joe")
  a = Store()
  a.set("a", 123)
  $foo(a.get("a"))  
  $foo(ticks)  
]]

local env = {foo = foo}


local code = safer_lua.init(0, init, loop, env, error)
if code then
	print(safer_lua.run_loop(0, code, error))
	safer_lua.run_loop(0, code, error)
	safer_lua.run_loop(0, code, error)
end