--[[

	sl_controller
	=============

	Copyright (C) 2018-2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	terminal.lua:
	
]]--

local HELP = [[#### SmartLine Controller Terminal ####

Send commands to your Controller
and output text messages from your
Controller to the Terminal.

Commands can have up to 80 characters.
Local commands:
- clear    = clear screen
- help     = this message 
- pub      = switch to public use
- priv      = switch to private use
Global commands:
- send <num> on/off  = send on/off event
- msg <num> <text>    = send a text message
]]

local function formspec1()
	return "size[6,4]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"field[0.5,1;5,1;number;SaferLua Controller number:;]" ..
	"button_exit[1.5,2.5;2,1;exit;Save]"
end

local function formspec2(meta)
	local output = meta:get_string("output")
	output = minetest.formspec_escape(output)
	output = output:gsub("\n", ",")
	return "size[9,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"table[0.1,0.1;8.6,6.6;output;"..output..";200]"..
	"field[0.5,7.6;6,1;cmnd;Enter command;]" ..
	"field_close_on_enter[cmnd;false]"..
	"button[6.7,7.3;2,1;ok;Enter]"
end

local function output(pos, text)
	local meta = minetest.get_meta(pos)
	text = meta:get_string("output") .. "\n" .. (text or "")
	text = text:sub(-500,-1)
	meta:set_string("output", text)
	meta:set_string("formspec", formspec2(meta))

end

local function command(pos, cmnd, player)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner") or ""
	if cmnd then
		cmnd = cmnd:sub(1,80)
		
		if cmnd == "clear" then
			meta:set_string("output", "")
			meta:set_string("formspec", formspec2(meta))
		elseif cmnd == "help" then
			local meta = minetest.get_meta(pos)
			meta:set_string("output", HELP)
			meta:set_string("formspec", formspec2(meta))
		elseif cmnd == "pub" and owner == player then
			meta:set_int("public", 1)
			output(pos, player..":$ "..cmnd)
			output(pos, "Switched to public use!")
		elseif cmnd == "priv" and owner == player then
			meta:set_int("public", 0)
			output(pos, player..":$ "..cmnd)
			output(pos, "Switched to private use!")
		elseif meta:get_int("public") == 1 or owner == player then
			-- send <num> on/off
			local num, topic = cmnd:match('^send%s+([0-9]+)%s+([onff]+)$')
			if num and topic then
				local own_number = meta:get_string("own_number")
				output(pos, player..":$ send "..num.." "..topic)
				tubelib.send_message(num, owner, nil, topic, own_number)
				return
			end
			-- msg <num> <text>
			local num, text = cmnd:match('^msg%s+([0-9]+)%s+(.+)$')
			if num and text then
				local own_number = meta:get_string("own_number")
				output(pos, player..":$ msg "..num.." "..text)
				tubelib.send_message(num, owner, nil, "msg", {src=own_number, text=text})
				return
			end
			local number = meta:get_string("number") or "0000"
			output(pos, player..":$ "..cmnd)
			tubelib.send_message(number, owner, nil, "term", cmnd)
		end
	end
end	

local function register_terminal(num, tiles, node_box, selection_box)
	minetest.register_node("sl_controller:terminal"..num, {
		description = "SaferLua Controller Terminal",
		tiles = tiles,
		drawtype = "nodebox",
		node_box = node_box,
		selection_box = selection_box,
		
		after_place_node = function(pos, placer)
			local number = tubelib.add_node(pos, minetest.get_node(pos).name)
			local meta = minetest.get_meta(pos)
			meta:set_string("own_number", number)
			meta:set_string("formspec", formspec1())
			meta:set_string("owner", placer:get_player_name())
			meta:set_string("infotext", "SaferLua Controller Terminal "..number..": not connected")
		end,

		on_receive_fields = function(pos, formname, fields, player)
			local meta = minetest.get_meta(pos)
			if fields.number and fields.number ~= "" then
				if tubelib.check_numbers(fields.number) then
					meta:set_string("number", fields.number)
					local own_number = meta:get_string("own_number")
					meta:set_string("infotext", "SaferLua Controller Terminal "..own_number..": connected with "..fields.number)
					meta:set_string("formspec", formspec2(meta))
				end
			elseif (fields.key_enter == "true" or fields.ok == "Enter") and fields.cmnd ~= "" then
				command(pos, fields.cmnd, player:get_player_name())
			end
		end,
		
		after_dig_node = function(pos)
			tubelib.remove_node(pos)
		end,
		
		paramtype = "light",
		sunlight_propagates = true,
		paramtype2 = "facedir",
		groups = {choppy=2, cracky=2, crumbly=2},
		is_ground_content = false,
		sounds = default.node_sound_metal_defaults(),
	})
end

register_terminal("", {
		-- up, down, right, left, back, front
		'sl_controller_terminal_top.png',
		'sl_controller_terminal_bottom.png',
		'sl_controller_terminal_side.png',
		'sl_controller_terminal_side.png',
		'sl_controller_terminal_bottom.png',
		"sl_controller_terminal_front.png",
	},
	{
		type = "fixed",
		fixed = {
			{-12/32, -16/32,  -8/32,  12/32, -14/32, 12/32},
			{-12/32, -14/32,  12/32,  12/32,   6/32, 14/32},
		},
	})

minetest.register_craft({
	output = "sl_controller:terminal",
	recipe = {
		{"", "smartline:display", ""},
		{"", "", ""},
		{"dye:black", "tubelib:wlanchip", "default:copper_ingot"},
	},
})

register_terminal("2", {
		-- up, down, right, left, back, front
		'sl_controller_terminal2_top.png',
		'sl_controller_terminal2_side.png',
		'sl_controller_terminal2_side.png^[transformFX',
		'sl_controller_terminal2_side.png',
		'sl_controller_terminal2_back.png',
		"sl_controller_terminal2_front.png",
	},
	{
		type = "fixed",
		fixed = {
			{-12/32, -16/32, -16/32,  12/32, -14/32, 16/32},
			{-12/32, -14/32,  -3/32,  12/32,   6/32, 16/32},
			{-10/32, -12/32,  14/32,  10/32,   4/32, 18/32},
			{-12/32,   4/32,  -4/32,  12/32,   6/32, 16/32},
			{-12/32, -16/32,  -4/32, -10/32,   6/32, 16/32},
			{ 10/32, -16/32,  -4/32,  12/32,   6/32, 16/32},
			{-12/32, -14/32,  -4/32,  12/32, -12/32, 16/32},
		},
	},
	{
		type = "fixed",
		fixed = {
			{-12/32, -16/32, -4/32,  12/32, 6/32, 16/32},
		},
	})

minetest.register_craft({
	output = "sl_controller:terminal2",
	recipe = {
		{"", "smartline:display", ""},
		{"", "", ""},
		{"dye:grey", "tubelib:wlanchip", "default:copper_ingot"},
	},
})

tubelib.register_node("sl_controller:terminal", {}, {
	on_recv_message = function(pos, topic, payload)
		if topic == "term" then
			output(pos, payload)
			return true
		elseif topic == "msg" then
			output(pos, payload.src..": "..payload.text)
			return true
		end
	end,
})

tubelib.register_node("sl_controller:terminal2", {}, {
	on_recv_message = function(pos, topic, payload)
		if topic == "term" then
			output(pos, payload)
			return true
		elseif topic == "msg" then
			output(pos, payload.src..": "..payload.text)
			return true
		end
	end,
})		

sl_controller.register_function("get_term", {
	cmnd = function(self)
		return sl_controller.get_command(self.meta.number)
	end,
	help = ' $get_term()  --> text string or nil\n'..
		' Read an entered string (command) from the Terminal.\n'..
		' example: s = $get_term()\n'..
		" The Terminal has to be connected to the controller."
})

sl_controller.register_action("put_term", {
	cmnd = function(self, num, text)
		text = tostring(text or "")
		tubelib.send_message(num, self.meta.owner, nil, "term", text)
	end,
	help = " $put_term(num, text)\n"..
		' Send a text line to the terminal with number "num".\n'..
		' example: $put_term("0123", "Hello "..name)'
})

sl_controller.register_function("get_msg", {
	cmnd = function(self)
		local msg = sl_controller.get_msg(self.meta.number)
		if msg then
			return msg.src, msg.text
		end
	end,
	help = ' $get_msg()  --> number and text string or nil\n'..
		' Read a received messages. Number is the node\n'..
		' number of the sender.\n'..
		' example: num,msg = $get_msg().'
})

sl_controller.register_action("send_msg", {
	cmnd = function(self, num, text)
		local msg = {src = self.meta.number, text = tostring(text or "")}
		tubelib.send_message(num, self.meta.owner, nil, "msg", msg)
	end,
	help = " $send_msg(num, text)\n"..
		' Send a message to the controller with number "num".\n'..
		' example: $send_msg("0123", "test")'
})

