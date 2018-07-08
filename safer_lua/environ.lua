--[[

	SaferLua [safer_lua]
	====================

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	environ.lua:

]]--

safer_lua.MaxCodeSize = 2000    -- size in length of byte code
safer_lua.MaxTableSize = 1000   -- sum over all table sizes


local function memsize()
	return safer_lua.MaxTableSize
end

local BASE_ENV = {
	Array = safer_lua.Array,
	Store = safer_lua.Store,
	Set = safer_lua.Set,
	memsize = memsize,
	math = {
		floor = math.floor,
		abs = math.abs,
		max = math.max,
		min = math.min,
		random = math.random,
	},
	tonumber = tonumber,
	tostring = tostring,
	type = type,
	ticks = 0,
}

local function map(dest, source)
  for k,v in pairs(source) do
    dest[k] = v
  end
  return dest
end

local function calc_used_mem_size(env)
	local size = 0
	for key,val in pairs(env) do
		if type(val) == "table" and val.size ~= nil then
			size = size + val.size() or 0
		end
	end
	return size
end

function safer_lua.config(max_code_size, max_table_size)
	safer_lua.MaxCodeSize = max_code_size
	safer_lua.MaxTableSize = max_table_size
end	

local function compile(pos, text, label, err_clbk)
	if safer_lua:check(pos, text, label, err_clbk) == 0 then
		text = text:gsub("%$", "S:")
		local code, err = loadstring(text)
		if not code then
			err = err:gsub("%(load%):", label)
			err_clbk(pos, err) 
		else
			return code
		end
	end
end

-------------------------------------------------------------------------------
-- Standard init/loop controller
-------------------------------------------------------------------------------
function safer_lua.init(pos, init, loop, environ, err_clbk)
	if #init > safer_lua.MaxCodeSize then
		err_clbk(pos, "init() Code size limit exceeded")
		return
	end
	if #loop > safer_lua.MaxCodeSize then
		err_clbk(pos, "loop() Code size limit exceeded")
		return
	end
	local code = compile(pos, init, "init() ", err_clbk)
	if code then
		local env = table.copy(BASE_ENV)
		env.S = {}
		env.S = map(env.S, environ)
		setfenv(code, env)
		local res, err = pcall(code)
		if not res then
			err = err:gsub("%[string .+%]:", "init() ")
			err_clbk(pos, err)
		else
			env = getfenv(code)
			code = compile(pos, loop, "loop() ", err_clbk)
			if code then
				setfenv(code, env)
				return code
			end
		end
	end
end

function safer_lua.run_loop(pos, elapsed, code, err_clbk)
	local env = getfenv(code)
	env.elapsed = elapsed
	if elapsed < 0 then  -- event?
		env.event = true
	else
		env.event = false
		env.ticks = env.ticks + 1
	end
	local res, err = pcall(code)
	if calc_used_mem_size(env) > safer_lua.MaxTableSize then 
		err_clbk(pos, "Memory limit exceeded")
		return false
	end
	if not res then
		err = err:gsub("%[string .+%]:", "loop() ")
		err_clbk(pos, err)
		return false
	end
	return true
end

-------------------------------------------------------------------------------
-- Endless/Coroutine controller
-------------------------------------------------------------------------------
local function thread(pos, code, err_clbk)
	while true do
		local res, err = pcall(code)
		if not res then
			err = err:gsub("%[string .+%]:", "loop() ")
			err_clbk(pos, err)
			return false
		end
		local env = getfenv(code)
		if calc_used_mem_size(env) > safer_lua.MaxTableSize then 
			err_clbk(pos, "Memory limit exceeded")
			return false
		end
		coroutine.yield()
	end
end	

function safer_lua.co_create(pos, init, loop, environ, err_clbk)
	local code = safer_lua.init(pos, init, loop, environ, err_clbk)
	return coroutine.create(thread), code
end

function safer_lua.co_resume(pos, co, code, err_clbk)
	local res, err = coroutine.resume(co, pos, code, err_clbk)
	if not res then
		err = err:gsub("%[string .+%]:", "loop() ")
		err_clbk(pos, err)
		return false
	end
	return true
end
