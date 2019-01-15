--[[

	sl_controller
	=============

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	commands.lua:
	
	Register all basic controller commands

]]--

sl_controller.register_function("get_input", {
	cmnd = function(self, num)
		num = tostring(num or "")
		return sl_controller.get_input(self.meta.number, num)
	end,
	help = ' $get_input(num)  --> "on", "off", or nil\n'..
		' Read local input value from device with number "num".\n'..
		' example: inp = $get_input("1234")\n'..
		" The device has to be connected with the controller."
})

sl_controller.register_function("get_status", {
	cmnd = function(self, num) 
		num = tostring(num or "")
		return tubelib.send_request(num, "state", nil)
	end,
	help = " $get_status(num) ,\n"..
		" Read status from a remote device. See\n"..
		" https://github.com/joe7575/techpack/wiki/nodes\n"..
		' example: sts = $get_status("1234")'
})

sl_controller.register_function("get_player_action", {
	cmnd = function(self, num) 
		num = tostring(num or "")
		return unpack(tubelib.send_request(num, "player_action", nil) or {"","",""})
	end,
	help = " $get_player_action(num) ,\n"..
		" Read player action status from a Tubelib chest. See\n"..
		" https://github.com/joe7575/techpack/wiki/nodes\n"..
		' example: player, action, item = $get_player_action("1234")'
})

sl_controller.register_function("get_counter", {
	cmnd = function(self, num) 
		num = tostring(num or "")
		return tubelib.send_request(num, "counter", nil)
	end,
	help = " $get_counter(num)\n"..
		" Read number of pushed items from a\n"..
		" Pusher/Distributor node.\n"..
		" The Pusher returns a single value (number)\n"..
		" The Distributor returns a list with 4 values\n"..
		" like: {red=1, green=0, blue=8, yellow=0}\n"..
		' example: cnt = $get_counter("1234")\n'
})

sl_controller.register_function("clear_counter", {
	cmnd = function(self, num) 
		num = tostring(num or "")
		return tubelib.send_request(num, "clear_counter", nil)
	end,
	help = " $clear_counter(num)\n"..
		" Set counter(s) from Pusher/Distributor to zero.\n"..
		' example: $clear_counter("1234")'
})

sl_controller.register_function("get_fuel_status", {
	cmnd = function(self, num) 
		num = tostring(num or "")
		return tubelib.send_request(num, "fuel", nil)
	end,
	help = " $get_fuel_status(num)\n"..
		" Read fuel status from Harverster and Quarry.\n"..
		' Fuel status is one of: "full","empty"\n'..
		' example: sts = $get_fuel_status("1234")'
})

sl_controller.register_function("get_num_items", {
	cmnd = function(self, num, idx) 
		num = tostring(num or "")
		idx = tonumber(idx)
		return tubelib.send_request(num, "num_items", idx)
	end,
	help = " $get_num_items(num)\n"..
		" Read number of stored items in one\n"..
		" storage (1..8) from a Warehouse Box.\n"..
		' example: cnt = $get_num_items("1234", 4)\n'
})

sl_controller.register_function("time_as_str", {
	cmnd = function(self) 
		local t = minetest.get_timeofday()
		local h = math.floor(t*24) % 24
		local m = math.floor(t*1440) % 60
		return string.format("%02d:%02d", h, m)
	end,
	help = " $time_as_str()  --> e.g. '18:45'\n"..
		" Read time of day as string (24h).\n"..
		' example: time = $time_as_str()'
})

sl_controller.register_function("time_as_num", {
	cmnd = function(self, num) 
		local t = minetest.get_timeofday()
		local h = math.floor(t*24) % 24
		local m = math.floor(t*1440) % 60
		return h * 100 + m
	end,
	help = " $time_as_num()  --> e.g.: 1845\n"..
		" Read time of day as number (24h).\n"..
		' example: time = $time_as_num()'
})

sl_controller.register_function("playerdetector", {
	cmnd = function(self, num) 
		num = tostring(num or "")
		return tubelib.send_request(num, "name", nil)
	end,
	help = ' $playerdetector(num) --> e.g. "Joe"\n'..
		' "" is returned if no player is nearby.\n'..
		' example: name = $playerdetector("1234")'
})

sl_controller.register_action("send_cmnd", {
	cmnd = function(self, num, text) 
		num = tostring(num or "")
		text = tostring(text or "")
		tubelib.send_message(num, self.meta.owner, nil, text, nil)
	end,
	help = " $send_cmnd(num, text)\n"..
		' Send a command to the device with number "num".\n'..
		" For more help, see:\n"..
		" https://github.com/joe7575/techpack/wiki/nodes\n"..
		' example: $send_cmnd("1234", "on")'
})

sl_controller.register_action("set_filter", {
	cmnd = function(self, num, slot, val) 
		num = tostring(num or "")
		slot = tostring(slot or "red")
		val = tostring(val or "on")
		tubelib.send_message(num, self.meta.owner, nil, "filter", {slot=slot, val=val})
	end,
	help = " $set_filter(num, slot, val)\n"..
		' Turn on/off a Distributor filter slot.\n'..
		" For more help, see:\n"..
		" https://github.com/joe7575/techpack/wiki/nodes\n"..
		' example: $set_filter("1234", "red", "off")'
})


sl_controller.register_action("display", {
	cmnd = function(self, num, row, text1, text2, text3)
		text1 = tostring(text1 or "")
		text2 = tostring(text2 or "")
		text3 = tostring(text3 or "")
		tubelib.send_message(num, self.meta.owner, nil, "row", {row = row, str = text1..text2..text3})
	end,
	help = " $display(num, row, text,...)\n"..
		' Send a text line to the display with number "num".\n'..
		" 'row' is a value from 1..9\n"..
		" The function accepts up to 3 text parameters\n"..
		' example: $display("0123", 1, "Hello ", name, " !")'
})

sl_controller.register_action("clear_screen", {
	cmnd = function(self, num) 
		num = tostring(num or "")
		tubelib.send_message(num, self.meta.owner, nil, "clear", nil)
	end,
	help = " $clear_screen(num)\n"..
		' Clear the screen of the display\n'..
		' with number "num".\n'..
		' example: $clear_screen("1234")'
})

sl_controller.register_action("chat", {
	cmnd = function(self, text1, text2, text3) 
		text1 = tostring(text1 or "")
		text2 = tostring(text2 or "")
		text3 = tostring(text3 or "")
		minetest.chat_send_player(self.meta.owner, "[SmartLine Controller] "..text1..text2..text3)
	end,
	help =  " $chat(text,...)\n"..
		" Send yourself a chat message.\n"..
		" The function accepts up to 3 text parameters\n"..
		' example: $chat("Hello ", name)'
})

sl_controller.register_action("door", {
	cmnd = function(self, pos, text) 
		pos = tostring(pos or "")
		text = tostring(text or "")
		pos = minetest.string_to_pos("("..pos..")")
		if pos then
			local door = doors.get(pos)
			if door then
				local player = {
					get_player_name = function() return self.meta.owner end,
					is_player = function() return true end,
				}
				if text == "open" then
					door:open(player)
				elseif text == "close" then
					door:close(player)
				end
			end
		end
	end,
	help =  " $door(pos, text)\n"..
		' Open/Close a door at position "pos"\n'..
		' example: $door("123,7,-1200", "close")\n'..
		" Hint: Use the Tubelib Programmer to\ndetermine the door position."
})
