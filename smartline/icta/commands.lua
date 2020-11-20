--[[

	ICTA Controller
	===============

	Part of the SmartLine mod
	
	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	command.lua:
	
	Register all controller commands

]]--

local sl = smartline

function sl.operand(s)
	if s == "is" then
		return "== "
	else
		return "~= "
	end
end

function sl.fmt_number(num)
	local mtch = num:match('^(%d+).*')
	if mtch and num ~= mtch then
		return mtch.."..."
	end
	return num
end

-- '#' is used as placeholder for rule numbers and has to be escaped
function smartline.escape(s)
	s = tostring(s)
	s  = s:gsub('\\', '')  -- to prevent code injection!!!
	s  = s:gsub('"', '\\"')  -- to prevent code injection!!!
	return s:gsub("#", '"..string.char(35).."')
end


smartline.icta_register_condition("initial", {
	title = "initial",
	formspec = {
		{
			type = "label", 
			name = "lbl", 
			label = "Condition is true only after\ncontroller start.", 
		},
	},
	-- Return two chunks of executable Lua code for the controller, according:
	--    return <read condition>, <expected result>
	code = function(data, environ) 
		return 'env.ticks', '== 1'
	end,
	button = function(data, environ) return "Initial after start" end,
})

smartline.icta_register_condition("true", {
	title = "true",
	formspec = {
		{
			type = "label", 
			name = "lbl", 
			label = "Condition is always true.", 
		},
	},
	code = function(data, environ) 
		return '"true"', '== "true"'
	end,
	button = function(data, environ) return "true" end,
})

smartline.icta_register_condition("condition", {
	title = "condition",
	formspec = {
		{
			type = "textlist", 
			name = "condition",
			label = "condition row number",      
			choices = "1,2,3,4,5,6,7,8", 
			default = "",
		},
		{
			type = "textlist",
			name = "operand",
			label = "condition",      
			choices = "was true, was not true",
			default = "was true",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Used to execute two or several\nactions based on one condition.", 
		},
	},
	code = function(data, environ) 
		local idx = data.condition:byte(-1) - 0x30
		local expected_result = "== false"
		if data.operand == "was true" then
			expected_result = "== true"
		end
		return "env.condition["..idx.."]", expected_result
	end,
	button = function(data, environ) return "cond("..data.condition:sub(-1,-1)..","..data.operand..")" end,
})

smartline.icta_register_condition("input", {
	title = "inputs",
	formspec = {
		{
			type = "digits",
			name = "number",
			label = "node number",
			default = "",
		},
		{
			type = "textlist",
			name = "operand",
			choices = "is,is not",
			default = "is",
		},
		{
			type = "textlist",
			name = "value",
			choices = "on,off,invalid",
			default = "on",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "An input is only available,\nif a nodes sends on/off\ncommands to the controller.", 
		},
	},
	button = function(data, environ)  -- default button label
		return 'inp('..sl.fmt_number(data.number)..','..data.operand.." "..data.value..')'
	end,
	code = function(data, environ)  
		return 'env.input["'..data.number..'"]',
			sl.operand(data.operand)..'"'..data.value..'"'
	end,
})

smartline.icta_register_condition("state", {
	title = "node state request",
	formspec = {
		{
			type = "digits",
			name = "number",
			label = "node number",
			default = "",
		},
		{
			type = "textlist",
			name = "operand",
			label = "",
			choices = "is,is not",
			default = "is",
		},
		{
			type = "textlist",
			name = "value",
			label = "",
			choices = "stopped,running,standby,blocked,defect,fault,invalid",
			default = "stopped",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Read the state from a node.\nWorks for Pusher, Harvester, Quarry,\n"..
				"and other similar nodes.", 
		},
	},
	button = function(data, environ)  -- default button label
		return 'sts('..sl.fmt_number(data.number)..","..data.operand..' '..data.value..')'
	end,
	code = function(data, environ) 
		return 'tubelib.send_request("'..data.number..'", "state", "")',
			sl.operand(data.operand)..'"'..data.value..'"'
	end,
})

smartline.icta_register_condition("fuel", {
	title = "fuel state request",
	formspec = {
		{
			type = "digits",
			name = "number",
			label = "node number",
			default = "",
		},
		{
			type = "textlist",
			name = "operand",
			label = "",
			choices = "is,is not",
			default = "is",
		},
		{
			type = "textlist",
			name = "value",
			label = "",
			choices = "full,loaded,empty,invalid",
			default = "full"
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Read the fuel state from a node.\nWorks for Harvester, Quarry,\n"..
				"and other fuel consuming nodes.", 
		},
	},
	button = function(data, environ) 
		return 'fuel('..sl.fmt_number(data.number)..","..data.operand..' '..data.value..')'
	end,
	code = function(data, environ) 
		return 'tubelib.send_request("'..data.number..'", "fuel", "")',
			sl.operand(data.operand)..'"'..data.value..'"'
	end,
})

smartline.icta_register_condition("chest", {
	title = "chest state request",
	formspec = {
		{
			type = "digits",
			name = "number",
			label = "chest number",
			default = "",
		},
		{
			type = "textlist",
			name = "operand",
			label = "",
			choices = "is,is not",
			default = "is",
		},
		{
			type = "textlist",
			name = "value",
			label = "",
			choices = "empty,loaded,invalid",
			default = "empty",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Read the state from a Tubelib chest\n"..
				"and other similar nodes.", 
		},
	},
	button = function(data, environ)  -- default button label
		return 'sts('..sl.fmt_number(data.number)..","..data.operand..' '..data.value..')'
	end,
	code = function(data, environ) 
		return 'tubelib.send_request("'..data.number..'", "state", "")',
			sl.operand(data.operand)..'"'..data.value..'"'
	end,
})

smartline.icta_register_condition("signaltower", {
	title = "Signal Tower state request",
	formspec = {
		{
			type = "digits",
			name = "number",
			label = "Signal Tower number",
			default = "",
		},
		{
			type = "textlist",
			name = "operand",
			choices = "is,is not",
			default = "is",
		},
		{
			type = "textlist",
			name = "value",
			choices = "off,green,amber,red,invalid",
			default = "off",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Read the color state\nfrom a Signal Tower.", 
		},
	},
	button = function(data, environ)  -- default button label
		return 'tower('..sl.fmt_number(data.number)..","..data.operand..' '..data.value..')'
	end,
	code = function(data, environ) 
		return 'tubelib.send_request("'..data.number..'", "state", "")',
			sl.operand(data.operand)..'"'..data.value..'"'
	end,
})

smartline.icta_register_action("signaltower", {
	title = "Signal Tower command",
	formspec = {
		{
			type = "numbers", 
			name = "number", 
			label = "Signal Tower number", 
			default = "",
		},
		{
			type = "textlist", 
			name = "value",
			label = "lamp color",      
			choices = "off,green,amber,red", 
			default = "red",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Turn on/off a Signal Tower lamp.", 
		},
	},
	button = function(data, environ) 
		return 'tower('..sl.fmt_number(data.number)..","..data.value..')'
	end,
	code = function(data, environ)
		local s = 'tubelib.send_message("%s", "%s", nil, "%s", nil)'
		return string.format(s, data.number, environ.owner, data.value)
	end,
})

smartline.icta_register_action("switch", {
	title = "turn node on/off",
	formspec = {
		{
			type = "numbers", 
			name = "number", 
			label = "node number(s)", 
			default = "",
		},
		{
			type = "textlist", 
			name = "value",
			label = "state",      
			choices = "on,off", 
			default = "on",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Used for pushers, lamps, machines, gates,...", 
		},
	},
	button = function(data, environ) 
		return 'turn('..sl.fmt_number(data.number)..","..data.value..')'
	end,
	code = function(data, environ)
		local s = 'tubelib.send_message("%s", "%s", nil, "%s", "%s")'
		return string.format(s, data.number, environ.owner, data.value, environ.number)
	end,
})

smartline.icta_register_action("display", {
	title = "Display: overwrite one line",
	formspec = {
		{
			type = "numbers", 
			name = "number", 
			label = "Display number", 
			default = "",
		},
		{
			type = "textlist", 
			name = "row", 
			label = "Display line", 
			choices = "1,2,3,4,5,6,7,8,9", 
			default = "1",
		},
		{
			type = "ascii", 
			name = "text",
			label = "text",      
			default = "",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Use a '*' character as reference\nto any condition result", 
		},
	},
	code = function(data, environ) 
		local s1 = string.format('local text = string.gsub("%s", "*", tostring(env.result[#]))', smartline.escape(data.text))
		local s2 = string.format('local payload = {row = %s, str = text}', data.row)
		local s3 = string.format('tubelib.send_message("%s", "%s", nil, "row", payload)', data.number, environ.owner)
		return s1.."\n\t"..s2.."\n\t"..s3
	end,
	button = function(data, environ) 
		return "lcd("..sl.fmt_number(data.number)..","..data.row..',"'..data.text..'")'
	end,
})

smartline.icta_register_action("cleardisplay", {
	title = "Display: Clear screen",
	formspec = {
		{
			type = "numbers", 
			name = "number", 
			label = "Display number", 
			default = "",
		},
	},
	code = function(data, environ) 
		return 'tubelib.send_message("'..data.number..'", "'..environ.owner..'", nil, "clear", nil)'
	end,
	button = function(data, environ) 
		return "clear lcd("..sl.fmt_number(data.number)..")"
	end,
})

smartline.icta_register_action("chat", {
	title = "chat send",
	formspec = {
		{
			type = "ascii", 
			name = "text",
			label = "message",      
			default = "",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "The chat message is send to the\nController owner, only.", 
		},
	},
	code = function(data, environ) 
		return 'minetest.chat_send_player("'..environ.owner..'", "[SmartLine Controller] '..smartline.escape(data.text)..'")'
	end,
	button = function(data, environ) 
		return 'chat("'..data.text:sub(1,12)..'")'
	end,
})

function smartline.icta_door_toggle(pos, owner, state)
	pos = minetest.string_to_pos("("..pos..")")
	if pos then
		local door = doors.get(pos)
		if door then
			local player = {
				get_player_name = function() return owner end,
				is_player = function() return true end,
			}
			if state == "open" then
				door:open(player)
			elseif state == "close" then
				door:close(player)
			end
		end
	end
end

smartline.icta_register_action("door", {
	title = "doors open/close",
	formspec = {
		{
			type = "digits", 
			name = "pos", 
			label = "door position like: 123,7,-1200", 
			default = "",
		},
		{
			type = "textlist", 
			name = "door_state",
			label = "door state",      
			choices = "open,close", 
			default = "open",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "For standard doors like the Steel Doors.\n"..
				"Use the Tubelib Programmer to\neasily determine a door position.", 
		},
	},
	code = function(data, environ) 
		return 'smartline.icta_door_toggle("'..data.pos..'", "'..environ.owner..'", "'..data.door_state..'")'
	end,
	button = function(data, environ) 
		return 'door("'..data.pos..'",'..data.door_state..")"
	end,
})

function smartline.icta_player_detect(number, name)
	local state = tubelib.send_request(number, "name", nil)
	if (name == "*" and state ~= "") or string.find(name, state) then
		return state
	end
	return nil
end

smartline.icta_register_condition("playerdetector", {
	title = "Player Detector name request",
	formspec = {
		{
			type = "digits",
			name = "number",
			label = "Player Detector number",
			default = "",
		},
		{
			type = "ascii",
			name = "name",
			label = "player name(s) or * for all",
			default = "",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Read and check the name\nfrom a Player Detector.\n Use a '*' character for all player names.", 
		},
	},
	
	code = function(data, environ) 
		return 'smartline.icta_player_detect("'..data.number..'", "'..smartline.escape(data.name)..'")', "~= nil"
	end,
	button = function(data, environ) 
		return "detector("..sl.fmt_number(data.number)..","..data.name:sub(1,8)..")"
	end,
})

smartline.icta_register_action("set_filter", {
	title = "turn Distributor filter on/off",
	formspec = {
		{
			type = "numbers", 
			name = "number", 
			label = "distri number", 
			default = "",
		},
		{
			type = "textlist", 
			name = "color",
			label = "filter port",      
			choices = "red,green,blue,yellow", 
			default = "red",
		},
		{
			type = "textlist", 
			name = "value",
			label = "state",      
			choices = "on,off", 
			default = "on",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "turn Distributor filter port on/off\n", 
		},
	},
	button = function(data, environ) 
		return 'turn('..sl.fmt_number(data.number)..","..data.color..","..data.value..')'
	end,
	code = function(data, environ)
		local payload = '{slot = "'..data.color..'", val = "'..data.value..'"}'
		local s = 'tubelib.send_message("%s", "%s", nil, "filter", %s)'
		return string.format(s, data.number, environ.owner, payload)
	end,
})

