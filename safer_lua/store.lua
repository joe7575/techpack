safer_lua.StoreHelp = [[
 Store - a secure shell over the LUA table type.
 
 For records: 
   tbl = Store()          --> {}
   tbl.set(key,value)  --> {key=value}
   tbl.get(key)           --> value
   
 'key' can be a number or string
 'value' can be number, string, boolean, or Store
 Example: tbl.set("a","test")
 
 For lists: 
   tbl = Store(1,2,3,4)  --> {1,2,3,4}
   tbl.insert(pos, value)   
   tbl.remove(pos)   
   
 'pos' must be a number
 
 Methods:
   tbl.set(key, value)   --> add/set a value
   tbl.get(key)	           --> read a value
   tbl.size()                 --> return the table size
   tbl.insert(pos, value) --> insert into list   
   tbl.remove(pos)       --> return and remove from list
   tbl.sort()                   -- sort list
   tbl.dump()               --> format as string (debugging)   
]]

function safer_lua.Store(...)

    local new_t = {__data__ = {}}
    local mt = {}
	
    -- `all` will represent the number of both
    local Count = 0

    mt.__newindex = function(t, k, v) return end
	
	mt.count = function(v)
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
	
	for idx = 1,select('#',...) do
		local v = select(idx,...)
		local cnt = mt.count(v)
		if cnt then
			Count = Count + cnt
			if Count < safer_lua.MaxTableSize then
				rawset(new_t.__data__,idx, v)
			end
		end
	end
	
	new_t.set = function(k,v)
		if type(k) == "string" or type(k) == "number" then
			Count = Count - mt.count(rawget(new_t.__data__, k))
			local cnt = mt.count(v)
			if cnt then
				Count = Count + cnt
				if Count < safer_lua.MaxTableSize then
					rawset(new_t.__data__,k,v)
				end
			end
		end
	end
 
	new_t.get = function(k)
		return rawget(new_t.__data__, k)
	end
	
	new_t.size = function(t)
		return Count
	end
 
	new_t.insert = function(v, i)
		local cnt = mt.count(v)
		if cnt then
			Count = Count + cnt
			if i == nil then i = #new_t.__data__ + 1 end
			if Count < safer_lua.MaxTableSize then
				table.insert(new_t.__data__,i,v)
			end
		end
	end
	
	new_t.remove = function(i)
		local v = table.remove(new_t.__data__,i)
		local cnt = mt.count(v)
		Count = Count - cnt
		return v
	end
	
	new_t.sort = function()
		table.sort(new_t.__data__)
	end
	
	new_t.dump = function(size)
		size = size or 200
		local s = dump(new_t.__data__)
		if #s > size then s = s:sub(1, size).."..." end
		return s
	end

return setmetatable(new_t, mt)
end
