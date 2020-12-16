--[[

	SmartLine
	=========

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	command.lua:
	
	Register all basic controller commands

]]--

smartline.register_condition("default", {
	title = "",
	formspec = {},
	on_execute = function(data, environ) end,
	button_label = function(data) return ""	end,
})

smartline.register_action("default", {
	title = "",
	formspec = {},
	on_execute = function(data, environ, number) end,
	button_label = function(data) return ""	end,
})


smartline.register_condition("true", {
	title = "true",
	formspec = {
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Condition is always true.", 
		},
	},
	on_execute = function(data, environ) 
		return true
	end,
	button_label = function(data) 
		return "true"
	end,
})

smartline.register_condition("false", {
	title = "false",
	formspec = {
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Condition is always false.", 
		},
	},
	on_execute = function(data, environ) 
		return false
	end,
	button_label = function(data) 
		return "false"
	end,
})

smartline.register_condition("toggle", {
	title = "toggle flag",
	formspec = {
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: This flag toggles (true/false) every two\nseconds and can be used to trigger\nan action every four seconds.", 
		},
	},
	on_execute = function(data, environ) 
		return environ.toggle
	end,
	button_label = function(data) 
		return "toggle"
	end,
})

smartline.register_condition("flag", {
	title = "flag",
	formspec = {
		{
			type = "textlist", 
			name = "flag",
			label = "flag",      
			choices = "f1,f2,f3,f4,f5,f6,f7,f8", 
			default = 1,
		},
		{
			type = "textlist", 
			name = "value", 
			label = "is", 
			choices = "true,false", 
			default = 1,
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: The flag will keep its state.", 
		},
	},
	on_execute = function(data, environ) 
		return environ.flags[data.flag] == data.value_text
	end,
	button_label = function(data) 
		return data.flag_text.."=="..data.value_text
	end,
})

smartline.register_condition("flag_reset", {
	title = "flag test and clear",
	formspec = {
		{
			type = "textlist", 
			name = "flag",
			label = "flag",      
			choices = "f1,f2,f3,f4,f5,f6,f7,f8", 
			default = 1,
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: The result is true, if the flag was true.\nAfter evaluation the flag is set to false.", 
		},
	},
	on_execute = function(data, environ) 
		local res = environ.flags[data.flag] == "true"
		environ.flags[data.flag] = "false"
		return res
	end,
	button_label = function(data) 
		return "test_clear("..data.flag_text..")"
	end,
})

smartline.register_action("flag", {
	title = "flag set",
	formspec = {
		{
			type = "textlist", 
			name = "flag",
			label = "set flag",      
			choices = "f1,f2,f3,f4,f5,f6,f7,f8", 
			default = 1,
		},
		{
			type = "textlist", 
			name = "value", 
			label = "to value", 
			choices = "true,false", 
			default = 1,
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Flags are stored permanently and\ncan be used as condition by other rules.", 
		},
	},
	on_execute = function(data, environ, number) 
		environ.flags[data.flag] = data.value_text
	end,
	button_label = function(data) 
		return data.flag_text.."="..data.value_text
	end,
})

smartline.register_condition("input", {
	title = "inputs",
	formspec = {
		{
			type = "field",
			name = "number",
			label = "input from node with number",
			default = "",
		},
		{
			type = "textlist",
			name = "value",
			label = "is",
			choices = "on,off,false",
			default = 1,
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: An input is only available,\nif the sending node is connected\nwith the controller.", 
		},
	},
	on_execute = function(data, environ) 
		return environ.inputs[data.number] == data.value_text
	end,
	button_label = function(data) 
		return "i("..data.number..")=="..data.value_text 
	end,
})


smartline.register_condition("timer", {
	title = "timer expired",
	formspec = {
		{
			type = "textlist", 
			name = "timer",
			label = "timer expired",
			choices = "t1,t2,t3,t4,t5,t6,t7,t8", 
			default = 1,
		},
	},
	on_execute = function(data, environ) 
		return environ.timers[data.timer] == 0
	end,
	button_label = function(data) 
		return data.timer_text.." expired"
	end,
})

smartline.register_action("timer", {
	title = "timer start",
	formspec = {
		{
			type = "textlist", 
			name = "timer",
			label = "start timer",      
			choices = "t1,t2,t3,t4,t5,t6,t7,t8", 
			default = 1,
		},
		{
			type = "field", 
			name = "value", 
			label = "value in sec.", 
			default = "",
		},
	},
	on_execute = function(data, environ, number) 
		environ.timers[data.timer] = tonumber(data.value) or 0
	end,
	button_label = function(data) 
		return data.timer_text.."="..data.value 
	end,
})

smartline.register_condition("pusher", {
	title = "node state request",
	formspec = {
		{
			type = "field",
			name = "number",
			label = "state from node with number",
			default = "",
		},
		{
			type = "textlist",
			name = "value",
			label = "is",
			choices = "stopped,running,standby,blocked,fault,defect,false",
			default = 1,
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Read the state from another node.\nWorks for Pusher, Harvester, Quarry,\nFermenter, and Reformer", 
		},
	},
	
	on_execute = function(data, environ) 
		environ.state = tubelib.send_request(data.number, "state", "")
		return environ.state == data.value_text
	end,
	button_label = function(data) 
		return "st("..data.number..")=="..string.sub(data.value_text or "???", 1, 4).."."
	end,
})

smartline.register_condition("fuel", {
	title = "fuel state request",
	formspec = {
		{
			type = "field",
			name = "number",
			label = "fuel state from node with number",
			default = "",
		},
		{
			type = "textlist",
			name = "value",
			label = "is",
			choices = "full,empty,not full,not empty,false",
			default = 1,
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Read the fuel state from another node.\nWorks for Harvester and Quarry", 
		},
	},
	
	on_execute = function(data, environ) 
		if data.value > 2 then
			return tubelib.send_request(data.number, "fuel", nil) ~= string.sub(data.value_text or "???", 5)
		else
			return tubelib.send_request(data.number, "fuel", nil) == data.value_text
		end
	end,
	button_label = function(data) 
		if data.value > 2 then
			return "st("..data.number..")<>"..string.sub(data.value_text or "???", 5)
		else
			return "st("..data.number..")=="..data.value_text
		end
	end,
})

smartline.register_condition("signaltower", {
	title = "Signal Tower state request",
	formspec = {
		{
			type = "field",
			name = "number",
			label = "state from Signal Tower with number",
			default = "",
		},
		{
			type = "textlist",
			name = "value",
			label = "is",
			choices = "off,green,amber,red,not off,not green,not amber,not red,false",
			default = 1,
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Read the state from a Signal Tower.", 
		},
	},
	
	on_execute = function(data, environ) 
		if data.value > 4 then
			return tubelib.send_request(data.number, "state", nil) ~= string.sub(data.value_text or "???", 5)
		else
			return tubelib.send_request(data.number, "state", nil) == data.value_text
		end
	end,
	button_label = function(data) 
		if data.value > 4 then
			return "sig("..data.number..")<>"..string.sub(data.value_text or "???", 5)
		else
			return "sig("..data.number..")=="..data.value_text
		end
	end,
})

smartline.register_action("signaltower", {
	title = "Signal Tower command",
	formspec = {
		{
			type = "field", 
			name = "number", 
			label = "set Signal Tower with number", 
			default = "",
		},
		{
			type = "textlist", 
			name = "value",
			label = "to color",      
			choices = "off,green,amber,red", 
			default = 1,
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Turn on a lamp from a Signal Tower.", 
		},
	},
	on_execute = function(data, environ, number) 
		tubelib.send_message(data.number, data.owner, nil, data.value_text, number)
	end,
	button_label = function(data) 
		return "sig("..data.number..","..data.value_text..")"
	end,
})

smartline.register_action("switch", {
	title = "node on/off command",
	formspec = {
		{
			type = "field", 
			name = "number", 
			label = "set node with number", 
			default = "",
		},
		{
			type = "textlist", 
			name = "value",
			label = "to state",      
			choices = "on,off", 
			default = 1,
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Used for pushers, lamps, machines, gates,...", 
		},
	},
	on_execute = function(data, environ, number) 
		tubelib.send_message(data.number, data.owner, nil, data.value_text, number)
	end,
	button_label = function(data) 
		return "cmnd("..data.number..","..data.value_text..")"
	end,
})

smartline.register_action("display1", {
	title = "Display: add one line",
	formspec = {
		{
			type = "field", 
			name = "number", 
			label = "output to Display with number", 
			default = "",
		},
		{
			type = "field", 
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
	on_execute = function(data, environ, number) 
		local text = string.gsub(data.text, "*", environ.state or "<unknown>")
		tubelib.send_message(data.number, data.owner, nil, "text", text)
	end,
	button_label = function(data) 
		return "display("..data.number..")"
	end,
})

smartline.register_action("display2", {
	title = "Display: overwrite one line",
	formspec = {
		{
			type = "field", 
			name = "number", 
			label = "output to Display with number", 
			default = "",
		},
		{
			type = "textlist", 
			name = "row", 
			label = "Display line", 
			choices = "1,2,3,4,5,6,7,8,9", 
			default = 1,
		},
		{
			type = "field", 
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
	on_execute = function(data, environ, number) 
		local text = string.gsub(data.text, "*", environ.state or "<unknown>")
		local payload = {row = data.row, str = text}
		tubelib.send_message(data.number, data.owner, nil, "row", payload)
	end,
	button_label = function(data) 
		return "display("..data.number..")"
	end,
})

smartline.register_action("display3", {
	title = "Display: player name",
	formspec = {
		{
			type = "field", 
			name = "number", 
			label = "output to Display with number", 
			default = "",
		},
		{
			type = "field", 
			name = "text",
			label = "the following text",      
			default = "",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Use a '*' character as reference to the\nplayer name", 
		},
	},
	on_execute = function(data, environ, number) 
		local text = string.gsub(data.text, "*", environ.state or "<unknown>")
		tubelib.send_message(data.number, data.owner, nil, "text", text)
	end,
	button_label = function(data) 
		return "display(<name>)"
	end,
})

smartline.register_action("display4", {
	title = "Display: Clear screen",
	formspec = {
		{
			type = "field", 
			name = "number", 
			label = "Display number", 
			default = "",
		},
	},
	on_execute = function(data, environ, number) 
		tubelib.send_message(data.number, data.owner, nil, "clear", "")
	end,
	button_label = function(data) 
		return "Clear screen"
	end,
})

if minetest.get_modpath("mail") and mail ~= nil then
	smartline.register_action("mail", {
		title = "mail send",
		formspec = {
			{
				type = "field", 
				name = "text",
				label = "send the message",      
				default = "",
			},
			{
				type = "label", 
				name = "lbl", 
				label = "Hint: The mail is send to the Controller owner, only.", 
			},
		},
		on_execute = function(data, environ, number) 
			mail.send("Server", data.owner, "[SmartLine Controller]", data.text)
		end,
		button_label = function(data) 
			return "mail(...)"
		end,
	})
end

smartline.register_action("chat", {
	title = "chat send",
	formspec = {
		{
			type = "field", 
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
	on_execute = function(data, environ, number)
		minetest.chat_send_player(data.owner, "[SmartLine Controller] "..data.text)
	end,
	button_label = function(data) 
		return "chat(...)"
	end,
})

local function door_toggle(pos, owner, state)
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

smartline.register_action("door", {
	title = "doors open/close",
	formspec = {
		{
			type = "field", 
			name = "pos", 
			label = "door position like: 123,7,-1200", 
			default = "",
		},
		{
			type = "textlist", 
			name = "door_state",
			label = "set",      
			choices = "open,close", 
			default = 1,
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
	on_execute = function(data, environ, number) 
		door_toggle(data.pos, data.owner, data.door_state_text)
	end,
	button_label = function(data) 
		return "door("..data.door_state_text..")"
	end,
})

smartline.register_condition("playerdetector", {
	title = "Player Detector: name request",
	formspec = {
		{
			type = "field",
			name = "number",
			label = "name from player detector with number",
			default = "",
		},
		{
			type = "field",
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
	
	on_execute = function(data, environ) 
		environ.state = tubelib.send_request(data.number, "name", nil)
		return (data.name == "*" and environ.state ~= "") or environ.state == data.name
	end,
	button_label = function(data) 
		if string.len(data.name) > 6 then
			return "name=="..string.sub(data.name or "???", 1, 6).."."
		end
		return "name=="..data.name
	end,
})

smartline.register_condition("action", {
	title = "actions",
	formspec = {
		{
			type = "textlist", 
			name = "action",
			label = "action is executed",      
			choices = "a1,a2,a3,a4,a5,a6,a7,a8,a9,a10", 
			default = 1,
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: The corresponding flag is set for each\nexecuted action. Useful to execute\nmore than one action with one condition.", 
		},
	},
	on_execute = function(data, environ) 
		return environ.actions[data.action] == true
	end,
	button_label = function(data) 
		return "action"..data.action
	end,
})


local function daytime()
	local t = minetest.get_timeofday()
	return string.format("%02d:%02d", math.floor(t*24) % 24, math.floor(t*1440) % 60)
end
	
smartline.register_condition("rtc", {
	title = "Read RTC",
	formspec = {
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: The condition is always false.\nThe time is available as state\n(see Display actions).", 
		},
	},
	
	on_execute = function(data, environ) 
		environ.state = daytime()
		return false
	end,
	button_label = function(data) 
		return "RTC"
	end,
})

