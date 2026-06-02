--[[

	SmartLine
	=========

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	flipflop.lua:
	A toggle flip-flop node.

	- Every received 'on' signal (not from the control input) toggles the output state.
	- The control input (configurable number) can set (on) or reset (off) the output directly.
	- On every state change an 'on' or 'off' signal is sent to the configured output numbers.

]]--

-- Load support for I18n
local S = smartline.S

local function formspec(meta)
	local numbers    = meta:get_string("numbers")
	local ctrl_num   = meta:get_string("ctrl_number")
	local state_str  = meta:get_int("state") == 1 and S("on") or S("off")
	return "size[7,7]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0.5,0.3;"..S("Output node numbers").."]"..
		"field[0.5,1.2;6,1;numbers;;"..numbers.."]"..
		"label[0.5,2.2;"..S("Control input number (set=on / reset=off)").."]"..
		"field[0.5,3.1;6,1;ctrl_number;;"..ctrl_num.."]"..
		"label[0.5,4.2;"..S("Current state: ")..state_str.."]"..
		"button_exit[2,5.2;3,1;exit;"..S("Save").."]"
end

local function send_output(pos)
	local meta     = minetest.get_meta(pos)
	local numbers  = meta:get_string("numbers")
	local owner    = meta:get_string("owner")
	local own_num  = meta:get_string("own_number")
	local state    = meta:get_int("state")
	local topic    = state == 1 and "on" or "off"
	tubelib.send_message(numbers, owner, nil, topic, own_num)
end

local function set_state(pos, new_state)
	local meta = minetest.get_meta(pos)
	local own_num = meta:get_string("own_number")
	local state_str = new_state == 1 and S("on") or S("off")
	meta:set_int("state", new_state)
	meta:set_string("infotext", S("SmartLine T-FlipFlop").." "..own_num..": "..state_str)
	meta:set_string("formspec", formspec(meta))
	-- Use minetest.after to break any synchronous call chain (e.g. ring wiring)
	-- and avoid Lua stack overflows.
	minetest.after(0, send_output, pos)
end

minetest.register_node("smartline:flipflop", {
	description = S("SmartLine T-FlipFlop"),
	inventory_image = "smartline_flipflop_inventory.png",
	wield_image     = "smartline_flipflop_inventory.png",
	tiles = {
		-- up, down, right, left, back, front
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png^smartline_flipflop.png",
	},

	drawtype = "nodebox",
	node_box = {
		type  = "fixed",
		fixed = {
			{ -6/32, -6/32, 14/32, 6/32, 6/32, 16/32 },
		},
	},

	after_place_node = function(pos, placer)
		local meta     = minetest.get_meta(pos)
		local own_num  = tubelib.add_node(pos, "smartline:flipflop")
		meta:set_string("own_number", own_num)
		meta:set_string("numbers", "")
		meta:set_string("ctrl_number", "")
		meta:set_int("state", 0)
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("formspec", formspec(meta))
		meta:set_string("infotext", S("SmartLine T-FlipFlop").." "..own_num..": "..S("off"))
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local meta  = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		if owner ~= player:get_player_name() then
			return
		end
		if fields.exit then
			if tubelib.check_numbers(fields.numbers) then
				meta:set_string("numbers", fields.numbers)
			elseif fields.numbers == "" then
				meta:set_string("numbers", "")
			end
			-- ctrl_number may be a single number or empty
			local ctrl = fields.ctrl_number or ""
			if ctrl == "" or tubelib.check_numbers(ctrl) then
				meta:set_string("ctrl_number", ctrl)
			end
			meta:set_string("formspec", formspec(meta))
		end
	end,

	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,

	paramtype          = "light",
	sunlight_propagates = true,
	paramtype2         = "facedir",
	groups             = {choppy=2, cracky=2, crumbly=2},
	is_ground_content  = false,
	sounds             = default.node_sound_stone_defaults(),
	on_blast           = function() end,
})


minetest.register_craft({
	output = "smartline:flipflop",
	recipe = {
		{"",         "default:mese_crystal", ""},
		{"dye:blue", "default:copper_ingot",  "tubelib:wlanchip"},
		{"",         "tubelib:wlanchip",       ""},
	},
})


tubelib.register_node("smartline:flipflop", {}, {
	on_recv_message = function(pos, topic, payload)
		local meta     = minetest.get_meta(pos)
		local ctrl_num = meta:get_string("ctrl_number")

		-- payload is the sender's node number
		if ctrl_num ~= "" and payload == ctrl_num then
			-- Control input: set or reset directly
			if topic == "on" then
				set_state(pos, 1)
			elseif topic == "off" then
				set_state(pos, 0)
			end
		elseif topic == "on" then
			-- Toggle input: every 'on' flips the state
			local state = meta:get_int("state")
			set_state(pos, state == 1 and 0 or 1)
		end
	end,
	on_node_load = function(pos)
		-- nothing to restart; flip-flop is purely event-driven
	end,
})
