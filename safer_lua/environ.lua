safer_lua.MaxCodeSize = 1000    -- size in length of byte code
safer_lua.MaxTableSize = 1000   -- number of table entries considering string lenghts


local BASE_ENV = {
	Store = safer_lua.Store,
	math = {
		floor = math.floor
	},
	ticks = 0,
}

local function map(dest, source)
  for k,v in pairs(source) do
    dest[k] = v
  end
  return dest
end

function safer_lua.config(max_code_size, max_table_size)
	safer_lua.MaxCodeSize = max_code_size
	safer_lua.MaxTableSize = max_table_size
end	

local function compile(pos, text, label, err_clbk)
	if safer_lua:check(text, label, err_clbk) == 0 then
		text = text:gsub("%$", "S:")
		local code, err = loadstring(text)
		if not code then
			err = err:gsub("%[string .+%]:", label)
			err_clbk(pos, err) 
		else
			return code
		end
	end
end

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
		local env = BASE_ENV
		env.S = {}
		env.S._G = _G
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
	env.event = false
	env.ticks = env.ticks + 1
	env.elapsed = elapsed
	setfenv(code, env)
	local res, err = pcall(code)
	if not res then
		err = err:gsub("%[string .+%]:", "loop() ")
		err_clbk(pos, err)
		return false
	end
	return true
end

function safer_lua.run_event(pos, code, err_clbk)
	local env = getfenv(code)
	env.event = true
	setfenv(code, env)
	local res, err = pcall(code)
	if not res then
		err = err:gsub("%[string .+%]:", "loop() ")
		err_clbk(pos, err)
		return false
	end
	return true
end


