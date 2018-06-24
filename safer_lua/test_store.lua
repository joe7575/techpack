core = {}

function core.global_exists(name)
	return false
end

dofile('/home/joachim/minetest/builtin/common/vector.lua')
dofile('/home/joachim/minetest/builtin/common/misc_helpers.lua')

safer_lua = {}
safer_lua.MaxTableSize = 1000   -- number of table entries considering string lenghts

dofile('/home/joachim/minetest/mods/techpack/safer_lua/store.lua')


print("S1")
local s1 = safer_lua.Store()
assert(s1.size() == 0)

s1.a = 3
s1[1] = 4
assert(s1.size() == 0)

s1.set("b", "Hallo")
assert(s1.size() == 5)

assert(s1.get("b") == "Hallo")
assert(s1.size() == 5)

print("S2")
local s2 = safer_lua.Store()
assert(s2.size() == 0)
s2.set("b", "Joe")
assert(s2.size() == 3)

assert(s2.b == nil)
assert(s2.get('b') == "Joe")
s2.c = "XXX!"
assert(s2.c == nil)

s1.set("c", s2)
print(dump(s1.get("c")))

print("S3")
local s3 = safer_lua.Store(1,2,3,4)
assert(s3.size() == 4)
print(dump(s3))

s3.insert(0, 1)
s3.insert(5)
print(s3.dump())
print(s2.dump())

s2.set("s2", s2)
print(s2.dump())

print(dump(s2))
