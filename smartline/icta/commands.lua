--[[

	ICTA Controller
	===============

	Part of the SmartLine mod
	
	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
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

-- '#' is used as placeholder for rule numbers and has to be escaped
function smartline.escape(s)
	return s:gsub("#", '"..string.char(35).."')
end


smartline.icta_register_condition("once", {
	title = "once",
	formspec = {
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Once after start.", 
		},
	},
	-- Return two chunks of executable Lua code for the controller, according:
	--    return <read condition>, <expected result>
	code = function(data, environ) 
		return 'env.ticks', '== 1'
	end,
	button = function(data, environ) return "once" end,
})

smartline.icta_register_condition("true", {
	title = "true",
	formspec = {
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Condition is always true.", 
		},
	},
	code = function(data, environ) 
		return '"true"', '== "true"'
	end,
	button = function(data, environ) return "true" end,
})

smartline.icta_register_condition("condition", {
	title = "Condition",
	formspec = {
		{
			type = "textlist", 
			name = "condition",
			label = "the action is executed, if",      
			choices = "condition 1,condition 2,condition 3,condition 4,condition 5,condition 6,condition 7,condition 8", 
			default = "",
		},
		{
			type = "textlist",
			name = "operand",
			choices = "was true, was not true",
			default = "was true",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Execute two or several actions\nbased on one condition.", 
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
	button = function(data, environ) return data.condition or "???" end,
})

smartline.icta_register_condition("input", {
	title = "inputs",
	formspec = {
		{
			type = "digits",
			name = "number",
			label = "input from node with number",
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
			choices = "on,off,false",
			default = "on",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: An input is only available,\nif a nodes sends on/of\ncommands to the controller.", 
		},
	},
	button = function(data, environ)  -- default button label
		return 'input('..(data.number or "???")..')'
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
			label = "state from node with number",
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
			choices = "stopped,running,standby,blocked,fault",
			default = "stopped",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Read the state from another node.\nWorks for Pusher, Harvester, Quarry,\nand others.", 
		},
	},
	button = function(data, environ)  -- default button label
		return 'state('..(data.number or "???")..')'
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
			label = "fuel state from node with number",
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
			choices = "full,loaded,empty",
			default = "full"
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Read the fuel state from another node.\nWorks for Harvester and Quarry", 
		},
	},
	button = function(data, environ) 
		return 'fuel('..(data.number or "???")..')'
	end,
	code = function(data, environ) 
		return 'tubelib.send_request("'..data.number..'", "fuel", "")',
			sl.operand(data.operand)..'"'..data.value..'"'
	end,
})

smartline.icta_register_condition("signaltower", {
	title = "Signal Tower state request",
	formspec = {
		{
			type = "digits",
			name = "number",
			label = "state from Signal Tower with number",
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
			choices = "off,green,amber,red",
			default = "off",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Read the state from a Signal Tower.", 
		},
	},
	button = function(data, environ)  -- default button label
		return 'tower('..(data.number or "???")..')'
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
			label = "set Signal Tower with number", 
			default = "",
		},
		{
			type = "textlist", 
			name = "value",
			label = "to color",      
			choices = "off,green,amber,red", 
			default = "red",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Turn on a lamp from a Signal Tower.", 
		},
	},
	button = function(data, environ) 
		return 'tower('..(data.value or "???")..')'
	end,
	code = function(data, environ)
		local s = 'tubelib.send_message("%s", "%s", nil, "%s", nil)'
		return string.format(s, data.number, environ.owner, data.value)
	end,
})

smartline.icta_register_action("switch", {
	title = "node on/off command",
	formspec = {
		{
			type = "numbers", 
			name = "number", 
			label = "set node with number", 
			default = "",
		},
		{
			type = "textlist", 
			name = "value",
			label = "to state",      
			choices = "on,off", 
			default = "on",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Used for pushers, lamps, machines, gates,...", 
		},
	},
	button = function(data, environ) 
		return 'turn('..(data.value or "???")..')'
	end,
	code = function(data, environ)
		local s = 'tubelib.send_message("%s", "%s", nil, "%s", nil)'
		return string.format(s, data.number, environ.owner, data.value)
	end,
})

smartline.icta_register_action("display", {
	title = "Display: overwrite one line",
	formspec = {
		{
			type = "numbers", 
			name = "number", 
			label = "output to Display with number", 
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
			label = "the following text",      
			default = "",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Use a '*' character as reference to any\ncondition state", 
		},
	},
	code = function(data, environ) 
		local s1 = string.format('local text = string.gsub("%s", "*", env.result[#])', smartline.escape(data.text))
		local s2 = string.format('local payload = {row = %s, str = text}', data.row)
		local s3 = string.format('tubelib.send_message("%s", "%s", nil, "row", payload)', data.number, environ.owner)
		return s1.."\n\t"..s2.."\n\t"..s3
	end,
	button = function(data, environ) 
		return "display("..(data.number or "???")..")"
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
		return "clear("..(data.number or "???")..")"
	end,
})

smartline.icta_register_action("chat", {
	title = "chat send",
	formspec = {
		{
			type = "ascii", 
			name = "text",
			label = "send the message",      
			default = "",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: The chat message is send to the\nController owner, only.", 
		},
	},
	code = function(data, environ) 
		return 'minetest.chat_send_player("'..environ.owner..'", "[SmartLine Controller] '..data.text..'")'
	end,
	button = function(data, environ) 
		return "chat(...)"
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
			label = "set",      
			choices = "open,close", 
			default = "open",
		},
		{
			type = "label", 
			name = "lbl1", 
			label = "For standard doors like the Steel Doors.", 
		},
		{
			type = "label", 
			name = "lbl2", 
			label = "Hint: Use the Tubelib Programmer to\ndetermine the door position.", 
		},
	},
	code = function(data, environ) 
		return 'smartline.icta_door_toggle("'..data.pos..'", "'..environ.owner..'", "'..data.door_state..'")'
	end,
	button = function(data, environ) 
		return "door("..(data.door_state or "???")..")"
	end,
})

function smartline.icta_player_detect(number, name)
	local state = tubelib.send_request(number, "name", nil)
	if (name == "*" and state ~= "") or state == name then
		return state
	end
	return nil
end

smartline.icta_register_condition("playerdetector", {
	title = "Player Detector: name request",
	formspec = {
		{
			type = "digits",
			name = "number",
			label = "name from player detector with number",
			default = "",
		},
		{
			type = "ascii",
			name = "name",
			label = "is",
			default = "",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Read and check the name\nfrom a Player Detector.\n Use a '*' character for all player names.", 
		},
	},
	
	code = function(data, environ) 
		return 'smartline.icta_player_detect("'..data.number..'", "'..data.name..'")', "~= nil"
	end,
	button = function(data, environ) 
		return "detector()"
	end,
})
