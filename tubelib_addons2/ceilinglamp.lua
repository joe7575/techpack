--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	ceilinglamp.lua:
	
]]--

-- Load support for I18n
local S = tubelib_addons2.S

local function switch_on(pos, node)
	node.name = "tubelib_addons2:ceilinglamp_on"
	minetest.swap_node(pos, node)
end	

local function switch_off(pos, node)
	node.name = "tubelib_addons2:ceilinglamp"
	minetest.swap_node(pos, node)
	local pos1 = {x=pos.x-5, y=pos.y-5, z=pos.z-5}
	local pos2 = {x=pos.x+5, y=pos.y+5, z=pos.z+5}
	minetest.fix_light(pos1, pos2)
end	

minetest.register_node("tubelib_addons2:ceilinglamp", {
	description = S("Tubelib Ceiling Lamp"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_addons2_ceilinglamp_top.png',
		'tubelib_addons2_ceilinglamp_bottom.png',
		'tubelib_addons2_ceilinglamp.png',
	},

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-5/16,  -5/16, -5/16, 5/16,  -7/16,  5/16},
			{-4/16,  -7/16, -4/16, 4/16,  -8/16,  4/16},
		},
	},
	selection_box = {
		type = "wallmounted",
		wall_top =    {-5/16,  5/16, -5/16,  5/16,  8/16,  5/16},
		wall_bottom = {-5/16, -8/16, -5/16,  5/16, -5/16,  5/16},
		wall_side =   {-8/16, -5/16, -5/16, -5/16,  5/16,  5/16}
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons2:ceilinglamp")
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Tubelib Ceiling Lamp").." "..number)
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
	paramtype2 = "wallmounted",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("tubelib_addons2:ceilinglamp_on", {
	description = S("Tubelib Ceiling Lamp"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_addons2_ceilinglamp_top.png',
		'tubelib_addons2_ceilinglamp_bottom.png',
		'tubelib_addons2_ceilinglamp.png',
	},

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-5/16,  -5/16, -5/16, 5/16,  -7/16,  5/16},
			{-4/16,  -7/16, -4/16, 4/16,  -8/16,  4/16},
		},
	},
	selection_box = {
		type = "wallmounted",
		wall_top =    {-5/16,  5/16, -5/16,  5/16,  8/16,  5/16},
		wall_bottom = {-5/16, -8/16, -5/16,  5/16, -5/16,  5/16},
		wall_side =   {-8/16, -5/16, -5/16, -5/16,  5/16,  5/16}
	},
	
	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_off(pos, node)
		end
	end,

	paramtype = "light",
	light_source = 12,	
	sunlight_propagates = true,
	paramtype2 = "wallmounted",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_craft({
	type = "shapeless",
	output = "tubelib_addons2:ceilinglamp 3",
	recipe = {"tubelib:lamp", "default:wood", "default:glass"},
})

tubelib.register_node("tubelib_addons2:ceilinglamp", {"tubelib_addons2:ceilinglamp_on"}, {
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "on" then
			switch_on(pos, node)
		elseif topic == "off" then
			switch_off(pos, node)
		end
	end,
})		
