--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017-2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	invisiblelamp.lua:
	
]]--


local function switch_on(pos, node)
	node.name = "tubelib_addons2:invisiblelamp_on"
	minetest.swap_node(pos, node)
end	

local function switch_off(pos, node)
	node.name = "tubelib_addons2:invisiblelamp"
	minetest.swap_node(pos, node)
	local pos1 = {x=pos.x-5, y=pos.y-5, z=pos.z-5}
	local pos2 = {x=pos.x+5, y=pos.y+5, z=pos.z+5}
	minetest.fix_light(pos1, pos2)
end	

minetest.register_node("tubelib_addons2:invisiblelamp", {
	description = "Tubelib Invisible Lamp",
	drawtype = "glasslike_framed_optional",
	tiles = {"tubelib_addons2_invisiblelamp.png"},
	inventory_image = 'tubelib_addons2_invisiblelamp_inventory.png',
	
	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons2:invisiblelamp")
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Tubelib Invisible Lamp "..number)
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
	walkable = false,
	is_ground_content = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("tubelib_addons2:invisiblelamp_on", {
	description = "Tubelib Invisible Lamp",
	drawtype = "glasslike_framed_optional",
	tiles = {"tubelib_addons2_invisiblelamp.png"},
	
	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_off(pos, node)
		end
	end,

	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,
	
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
	sunlight_propagates = true,
	walkable = false,
	is_ground_content = false,
	drop = "tubelib_addons2:invisiblelamp",
	groups = {cracky = 3, oddly_breakable_by_hand = 3, not_in_creative_inventory=1},
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_craft({
	output = "tubelib_addons2:invisiblelamp 2",
	recipe = {
		{"", "default:torch", ""},
		{"default:torch", "tubelib:wlanchip", "default:torch"},
		{"", "default:torch", ""},
	}
})

tubelib.register_node("tubelib_addons2:invisiblelamp", {"tubelib_addons2:invisiblelamp_on"}, {
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "on" then
			switch_on(pos, node)
		elseif topic == "off" then
			switch_off(pos, node)
		end
	end,
})		
