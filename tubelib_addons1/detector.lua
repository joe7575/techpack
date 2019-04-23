--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017-2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	detector.lua:
	
]]--


local function switch_on(pos)
	if tubelib.data_not_corrupted(pos) then
		local node = minetest.get_node(pos)
		node.name = "tubelib_addons1:detector_active"
		minetest.swap_node(pos, node)
		minetest.get_node_timer(pos):start(1)
		local meta = minetest.get_meta(pos)
		local own_num = meta:get_string("own_num")
		local numbers = meta:get_string("numbers")
		local placer_name = meta:get_string("placer_name")
		tubelib.send_message(numbers, placer_name, nil, "on", own_num)
	end
end

local function switch_off(pos)
	if tubelib.data_not_corrupted(pos) then
		local node = minetest.get_node(pos)
		node.name = "tubelib_addons1:detector"
		minetest.swap_node(pos, node)
		local meta = minetest.get_meta(pos)
		local own_num = meta:get_string("own_num")
		local numbers = meta:get_string("numbers")
		local placer_name = meta:get_string("placer_name")
		tubelib.send_message(numbers, placer_name, nil, "off", own_num)
	end
end


minetest.register_node("tubelib_addons1:detector", {
	description = "Tubelib Detector",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_outp.png',
		'tubelib_inp.png',
		'tubelib_addons1_detector.png^[transformFX',
		"tubelib_addons1_detector.png",
	},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local own_num = tubelib.add_node(pos, "tubelib_addons1:detector")
		meta:set_string("own_num", own_num)
		meta:set_string("formspec", "size[7.5,3]"..
		"field[0.5,1;7,1;numbers;Insert destination node number(s);]" ..
		"button_exit[2,2;3,1;exit;Save]")
		meta:set_string("placer_name", placer:get_player_name())
		meta:set_string("infotext", "Tubelib Detector, unconfigured")
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local meta = minetest.get_meta(pos)
		if tubelib.check_numbers(fields.numbers) then
			meta:set_string("numbers", fields.numbers)
			local own_num = meta:get_string("own_num")
			meta:set_string("infotext", "Tubelib Detector, connected")
			meta:set_string("formspec", "size[7.5,3]"..
			"field[0.5,1;7,1;numbers;Insert destination node number(s);"..fields.numbers.."]" ..
			"button_exit[2,2;3,1;exit;Save]")
		end
	end,
	
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		tubelib.remove_node(pos)
	end,
	
	on_rotate = screwdriver.disallow,
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_node("tubelib_addons1:detector_active", {
	description = "Tubelib Detector",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_outp.png',
		'tubelib_inp.png',
		'tubelib_addons1_detector_active.png^[transformFX',
		"tubelib_addons1_detector_active.png",
	},

	on_timer = switch_off,
	on_rotate = screwdriver.disallow,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		tubelib.remove_node(pos)
	end,
	
	paramtype = "light",
	light_source = 2,
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	drop = "tubelib_addons1:detector",
})

minetest.register_craft({
	output = "tubelib_addons1:detector",
	recipe = {
		{"", "group:wood", ""},
		{"tubelib:tubeS", "tubelib:wlanchip", "tubelib:tubeS"},
		{"", "group:wood", ""},
	},
})


tubelib.register_node("tubelib_addons1:detector", {"tubelib_addons1:detector_active"}, {
	on_push_item = function(pos, side, item)
		local player_name = minetest.get_meta(pos):get_string("player_name")
		if tubelib.push_items(pos, "R", item, player_name) then
			switch_on(pos)
			return true
		end
		return false
	end,
	is_pusher = true,  -- is a pulling/pushing node
})	

