--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017-2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	streetlamp.lua:
	
]]--


local function switch_on(pos, node)
	node.name = "tubelib_addons2:streetlamp_on"
	minetest.swap_node(pos, node)
end	

local function switch_off(pos, node)
	node.name = "tubelib_addons2:streetlamp"
	minetest.swap_node(pos, node)
end	

minetest.register_node("tubelib_addons2:streetlamp", {
	description = "Tubelib Street Lamp",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_addons2_streetlamp_top.png',
		'tubelib_addons2_streetlamp_top.png',
		'tubelib_addons2_streetlamp_off.png',
	},

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-5/16, -8/16, -5/16, 5/16,  8/16,  5/16},
			{-2/16, -8/16, -2/16, 2/16,  8/16,  2/16},
			{-8/16,  4/16, -8/16, 8/16,  5/16,  8/16},
			{-5/16, -8/16, -5/16, 5/16, -7/16,  5/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -8/16,   8/16, 8/16, 8/16},
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons2:streetlamp")
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Tubelib Street Lamp "..number)
	end,

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_on(pos, node)
		end
	end,

	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,

	paramtype = "light",
	light_source = 0,	
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("tubelib_addons2:streetlamp_on", {
	description = "Tubelib Street Lamp",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_addons2_streetlamp_top.png',
		'tubelib_addons2_streetlamp_top.png',
		'tubelib_addons2_streetlamp.png',
	},

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-5/16, -8/16, -5/16,  5/16, 8/16,  5/16},
			{-8/16,  4/16, -8/16,  8/16, 5/16,  8/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -8/16,   8/16, 8/16, 8/16},
	},
	
	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_off(pos, node)
		end
	end,

	paramtype = "light",
	light_source = minetest.LIGHT_MAX,	
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	type = "shapeless",
	output = "tubelib_addons2:streetlamp 2",
	recipe = {"tubelib:lamp", "default:steel_ingot", "default:glass"},
})

--------------------------------------------------------------- tubelib
tubelib.register_node("tubelib_addons2:streetlamp", {"tubelib_addons2:streetlamp_on"}, {
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "on" then
			switch_on(pos, node)
		elseif topic == "off" then
			switch_off(pos, node)
		end
	end,
})		
--------------------------------------------------------------- tubelib.