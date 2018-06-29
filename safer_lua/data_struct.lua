--[[

	SaferLua [safer_lua]
	====================

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	data_struct.lua:
	
	see https://github.com/joe7575/techpack/wiki/Data-Structures

]]--

safer_lua.DataStructHelp = [[
 Data structures as a secure shell over the LUA table type.
 see https://github.com/joe7575/techpack/wiki/Data-Structures
 
 'Arrays' are lists of elements, which can be addressed 
 by means of an index:
 
  a = Array(1,2,3,4)     --> {1,2,3,4}
  a.add(6)               --> {1,2,3,4,6}
  a.set(2, 8)            --> {1,8,3,4,6}
  a.insert(5,7)          --> {1,8,3,4,7,6}
  a.remove(3)            --> {1,8,4,7,6}
  a.insert(1, "hello")   --> {"hello",1,8,4,7,6}
  a.size()               --> function returns 10

 Unlike arrays, which are indexed by a range of numbers, 
 'stores' are indexed by keys:
 
  s = Store()            --> {}
  s.set("val", 12)       --> {val = 12}
  s.get("val")           --> returns 12
  s.set(0, "hello")      --> {val = 12, [0] = "hello"}
  s.del("val")           --> {[0] = "hello"}
  s.size()               --> function returns 6

 A 'set' is an unordered collection with no duplicate 
 elements.
 
  s = Set("Tom", "Lucy")     
                     --> {Tom = true, Lucy = true}
  s.del("Tom")       --> {Lucy = true}
  s.add("Susi")      --> {Lucy = true, Susi = true}
  s.has("Susi")      --> function returns `true`
  s.has("Mike")      --> function returns `false`
  s.size()           --> function returns 11
]]

local function var_count(v)
	if type(v) == "number" then
		return 1
	elseif type(v) == "boolean" then
		return 1
	elseif v == nil then
		return 0
	elseif type(v) == "string" then
		return #v
	elseif type(v) == "table" then
		return v.size()
	else
		return nil
	end
end


function safer_lua.Store()

    local new_t = {__data__ = {}}
    local mt = {}
	
    -- `all` will represent the number of both
    local Count = 0

    mt.__newindex = function(t, k, v) return end
	
	mt.count = var_count
	
	new_t.set = function(k,v)
		if type(k) == "number" then
			Count = Count - mt.count(rawget(new_t.__data__, k))
			Count = Count + mt.count(v)
			rawset(new_t.__data__,k,v)
		elseif type(k) == "string" then
			if rawget(new_t.__data__, k) then  -- has entry?
				Count = Count - mt.count(rawget(new_t.__data__, k))
			else
				Count = Count + mt.count(k)
			end
			Count = Count + mt.count(v)
			rawset(new_t.__data__,k,v)
		end
	end
 
	new_t.get = function(k)
		return rawget(new_t.__data__, k)
	end
	
	new_t.del = function(k)
		Count = Count - mt.count(k)
		Count = Count - mt.count(rawget(new_t.__data__, k))
		rawset(new_t.__data__,k,nil)
	end
	
	new_t.size = function(t)
		return Count
	end
 
	new_t.dump = function(size)
		size = size or 200
		local s = dump(new_t.__data__)
		if #s > size then s = s:sub(1, size).."..." end
		return s
	end
	
	return setmetatable(new_t, mt)
end


function safer_lua.Array(...)

    local new_t = {__data__ = {}}
    local mt = {}
	
    -- `all` will represent the number of both
    local Count = 0

    mt.__newindex = function(t, k, v) return end
	
	mt.count = var_count
	
	for idx = 1,select('#',...) do
		local v = select(idx,...)
		local cnt = mt.count(v)
		if cnt then
			Count = Count + cnt
			rawset(new_t.__data__,idx, v)
		end
	end
	
	new_t.add = function(v)
		Count = Count + mt.count(v)
		local i = #new_t.__data__ + 1
		table.insert(new_t.__data__,i,v)
	end
	
	new_t.set = function(i,v)
		i = math.min(#new_t.__data__, i) 
		Count = Count - mt.count(rawget(new_t.__data__, i))
		Count = Count + mt.count(v)
		rawset(new_t.__data__,i,v)
	end
 
	new_t.insert = function(i, v)
		Count = Count + mt.count(v)
		i = math.min(#new_t.__data__, i) 
		table.insert(new_t.__data__,i,v)
	end
	
	new_t.remove = function(i)
		local v = table.remove(new_t.__data__,i)
		Count = Count - mt.count(v)
		return v
	end
	
	new_t.size = function(t)
		return Count
	end
 
	new_t.dump = function(size)
		size = size or 200
		local s = dump(new_t.__data__)
		if #s > size then s = s:sub(1, size).."..." end
		return s
	end
	
	return setmetatable(new_t, mt)
end


function safer_lua.Set(...)

    local new_t = {__data__ = {}}
    local mt = {}
	
    -- `all` will represent the number of both
    local Count = 0

    mt.__newindex = function(t, k, v) return end
	
	mt.count = var_count
	
	for idx = 1,select('#',...) do
		local v = select(idx,...)
		local cnt = mt.count(v)
		if cnt then
			Count = Count + cnt
			rawset(new_t.__data__,v, true)
		end
	end
	
	new_t.add = function(k)
		Count = Count + mt.count(k)
		rawset(new_t.__data__,k, true)
	end
	
	new_t.del = function(k)
		Count = Count - mt.count(k)
		rawset(new_t.__data__,k, nil)
	end
	
	new_t.has = function(k)
		return rawget(new_t.__data__, k) == true
	end
	
	new_t.size = function(t)
		return Count
	end
 
	new_t.dump = function(size)
		size = size or 200
		local s = dump(new_t.__data__)
		if #s > size then s = s:sub(1, size).."..." end
		return s
	end

	return setmetatable(new_t, mt)
end
