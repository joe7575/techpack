--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	repeater.lua:
	
]]--

local OVER_LOAD_MAX = 5

local function formspec(meta)
	local numbers = meta:get_string("numbers")
	return "size[7,5]"..
		"field[0.5,2;6,1;number;Destination node numbers;"..numbers.."]" ..
		"button_exit[1,3;2,1;exit;Save]"
end	

minetest.register_node("tubelib_addons2:repeater", {
	description = "Tubelib Repeater",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png^tubelib_addon2_repeater.png',
	},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local own_number = tubelib.add_node(pos, "tubelib_addons2:repeater")
		meta:set_string("own_number", own_number)
		meta:set_string("formspec", formspec(meta))
		meta:set_string("infotext", "Tubelib Repeater "..own_number..": not connected")
		meta:set_string("owner", placer:get_player_name())
		meta:set_int("overload_cnt", 0)
		minetest.get_node_timer(pos):start(1)
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		if owner ~= player:get_player_name() then
			return
		end
		
		if tubelib.check_numbers(fields.number) then
			meta:set_string("numbers", fields.number)
			local own_number = meta:get_string("own_number")
			meta:set_string("infotext", "Tubelib Repeater "..own_number..": connected with "..fields.number)
			meta:set_string("formspec", formspec(meta))
		end
		
		local timer = minetest.get_node_timer(pos)
		if not timer:is_started() then
			timer:start(1)
		end
	end,
	
	on_timer = function(pos,elapsed)
		if tubelib.data_not_corrupted(pos) then
			local meta = minetest.get_meta(pos)
			meta:set_int("overload_cnt", 0)
			return true
		end
		return false
	end,
	
	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
})


minetest.register_craft({
	output = "tubelib_addons2:repeater",
	recipe = {
		{"", "group:wood", ""},
		{"tubelib:wlanchip", "", "tubelib:wlanchip"},
		{"", "group:wood", ""},
	},
})

tubelib.register_node("tubelib_addons2:repeater", {}, {
	on_recv_message = function(pos, topic, payload)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		local numbers = meta:get_string("numbers")
		local overload_cnt = meta:get_int("overload_cnt") + 1
		meta:set_int("overload_cnt", overload_cnt)
		if overload_cnt > OVER_LOAD_MAX then
			local own_number = meta:get_string("own_number")
			meta:set_string("infotext", "Tubelib Repeater "..own_number..": fault (overloaded)")
			minetest.get_node_timer(pos):stop()
			return false
		elseif topic == "set_numbers" then
			local own_number = meta:get_string("own_number")
			meta:set_string("infotext", "Tubelib Repeater "..own_number..": connected with "..payload)
			meta:set_string("numbers", payload)
			meta:set_string("formspec", formspec(meta))
			return true
		else
			return tubelib.send_message(numbers, owner, nil, topic, payload)
		end
	end,
	on_node_load = function(pos)
		minetest.get_node_timer(pos):start(1)
	end,
})		
