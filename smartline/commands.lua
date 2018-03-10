--[[

	SmartLine
	=========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	command.lua:
	
	Register all basic controller commands

]]--

smartline.register_condition("default", {
	title = "",
	formspec = {},
	on_execute = function(data, flags, timers, inputs, actions) end,
	button_label = function(data) return ""	end,
})

smartline.register_action("default", {
	title = "",
	formspec = {},
	on_execute = function(data, flags, timers, inputs) end,
	button_label = function(data) return ""	end,
})


smartline.register_condition("true", {
	title = "true",
	formspec = {},
	on_execute = function(data, flags, timers, inputs, actions) 
		return true
	end,
	button_label = function(data) 
		return "true"
	end,
})

smartline.register_condition("false", {
	title = "false",
	formspec = {},
	on_execute = function(data, flags, timers, inputs, actions) 
		return false
	end,
	button_label = function(data) 
		return "false"
	end,
})

smartline.register_condition("flag", {
	title = "flag test",
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
			label = "Hint: Don't forget to reset the flag again.", 
		},
	},
	on_execute = function(data, flags, timers, inputs, actions) 
		return flags[data.flag] == data.value_text
	end,
	button_label = function(data) 
		return data.flag_text.."=="..data.value_text
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
			label = "Hint: Flags are stored permanently and can be used by other rules.", 
		},
	},
	on_execute = function(data, flags, timers, number) 
		flags[data.flag] = data.value_text
	end,
	button_label = function(data) 
		return data.flag_text.."="..data.value_text
	end,
})

smartline.register_condition("input", {
	title = "check input",
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
			choices = "on,off",
			default = 1,
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: An input is only available,\nif the sending node is connected with the controller.", 
		},
	},
	on_execute = function(data, flags, timers, inputs, actions) 
		return inputs[data.number] == data.value_text
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
	on_execute = function(data, flags, timers, inputs, actions) 
		return timers[data.timer] == 0
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
	on_execute = function(data, flags, timers, number) 
		timers[data.timer] = tonumber(data.value) or 0
	end,
	button_label = function(data) 
		return data.timer_text.."="..data.value 
	end,
})

smartline.register_condition("pusher", {
	title = "Pusher state",
	formspec = {
		{
			type = "field",
			name = "number",
			label = "state from Pusher with number",
			default = "",
		},
		{
			type = "textlist",
			name = "value",
			label = "is",
			choices = "stopped,running,standby,blocked,fault",
			default = 1,
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint:\n - standby means 'nothing to do'\n - blocked means 'inventory is full'", 
		},
	},
	
	on_execute = function(data, flags, timers, inputs, actions) 
		return tubelib.send_request(data.number, "state", "") == data.value_text
	end,
	button_label = function(data) 
		return "st("..data.number..")=="..string.sub(data.value_text or "???", 1, 4).."."
	end,
})

smartline.register_condition("fuel", {
	title = "fuel state",
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
			choices = "full,empty,not full,not empty",
			default = 1,
		},
	},
	
	on_execute = function(data, flags, timers, inputs, actions) 
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
	title = "Signal Tower state",
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
			choices = "off,green,amber,red,not off,not green,not amber,not red",
			default = 1,
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Works also for Signal Towers in unloaded areas.", 
		},
	},
	
	on_execute = function(data, flags, timers, inputs, actions) 
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
	},
	on_execute = function(data, flags, timers, number) 
		tubelib.send_message(data.number, data.owner, nil, data.value_text, number)
	end,
	button_label = function(data) 
		return "sig("..data.number..","..data.value_text..")"
	end,
})

smartline.register_action("switch", {
	title = "switch nodes on/off",
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
	on_execute = function(data, flags, timers, number) 
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
			label = "Hint: Works also for Displays in unloaded areas.", 
		},
	},
	on_execute = function(data, flags, timers, number) 
		tubelib.send_message(data.number, data.owner, nil, "text", data.text)
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
			label = "Hint: Works also for Displays in unloaded areas.", 
		},
	},
	on_execute = function(data, flags, timers, number) 
		local payload = {row = data.row, str = data.text}
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
			label = "Hint: use a '*' character as reference to the player name", 
		},
	},
	on_execute = function(data, flags, timers, number) 
		local text = string.gsub(data.text, "*", flags.name or "<unknown>")
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
	on_execute = function(data, flags, timers, number) 
		tubelib.send_message(data.number, data.owner, nil, "clear", "")
	end,
	button_label = function(data) 
		return "Clear screen"
	end,
})

if minetest.get_modpath("mail") and mail ~= nil then
	smartline.register_action("mail", {
		title = "mail",
		formspec = {
			{
				type = "field", 
				name = "text",
				label = "send the message",      
				default = "",
			},
		},
		on_execute = function(data, flags, timers, number) 
			mail.send("Server", data.owner, "[SmartLine Controller]", data.text)
		end,
		button_label = function(data) 
			return "mail(...)"
		end,
	})
end

smartline.register_action("chat", {
	title = "chat",
	formspec = {
		{
			type = "field", 
			name = "text",
			label = "send the message",      
			default = "",
		},
	},
	on_execute = function(data, flags, timers, number)
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
			name = "state",
			label = "set",      
			choices = "open,close", 
			default = 1,
		},
		{
			type = "label", 
			name = "lbl1", 
			label = "For standard doors like the Steel Door", 
		},
		{
			type = "label", 
			name = "lbl2", 
			label = "Hint: use a marker stick to determine the door position", 
		},
	},
	on_execute = function(data, flags, timers, number) 
		door_toggle(data.pos, data.owner, data.state_text)
	end,
	button_label = function(data) 
		return "door("..data.state_text..")"
	end,
})

smartline.register_condition("playerdetector", {
	title = "detected player name",
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
			label = "Hint: use a '*' character for all player names", 
		},
	},
	
	on_execute = function(data, flags, timers, inputs, actions) 
		flags.name = tubelib.send_request(data.number, "name", nil)
		return (data.name == "*" and flags.name ~= "") or flags.name == data.name
	end,
	button_label = function(data) 
		if string.len(data.name) > 6 then
			return "name=="..string.sub(data.name or "???", 1, 6).."."
		end
		return "name=="..data.name
	end,
})

smartline.register_condition("action", {
	title = "action",
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
			label = "Hint: The corresponding flag is set for each\nexecute action. Useful to execute\nmore than one action with one condition.", 
		},
	},
	on_execute = function(data, flags, timers, inputs, actions) 
		return actions[data.action] == true
	end,
	button_label = function(data) 
		return "action"..data.action
	end,
})

