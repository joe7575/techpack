--[[

	Tubes based on tubelib2
	=======================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	tubes.lua: Node registration and API functions to move items via tubes

]]--

-- Load support for I18n
local S = tubelib.S

-- used for registered nodes
tubelib.KnownNodes = {
	["tubelib:tubeS"] = true,
	["tubelib:tubeA"] = true,
}


local Tube = tubelib2.Tube:new({
	                -- North, East, South, West, Down, Up
	dirs_to_check = {1,2,3,4,5,6},
	max_tube_length = 200, 
	show_infotext = false,
	primary_node_names = {"tubelib:tubeS", "tubelib:tubeA"}, 
	after_place_tube = function(pos, param2, tube_type, num_tubes, tbl)
		minetest.swap_node(pos, {name = "tubelib:tube"..tube_type, param2 = param2})
	end,
})

tubelib.Tube = Tube

local function ON_BLAST(id)
	return function (pos)
		local node = minetest.get_node(pos)
		minetest.remove_node(pos)
		Tube:after_dig_tube(pos, node)
		return {id}
	end
end

minetest.register_node("tubelib:tubeS", {
	description = S("Tubelib Tube"),
	tiles = { -- Top, base, right, left, front, back
		"tubelib_tube.png^[transformR90",
		"tubelib_tube.png^[transformR90",
		"tubelib_tube.png",
		"tubelib_tube.png",
		"tubelib_hole.png",
		"tubelib_hole.png",
	},
	
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		if not Tube:after_place_tube(pos, placer, pointed_thing) then
			minetest.remove_node(pos)
			return true
		end
		return false
	end,
	
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Tube:after_dig_tube(pos, oldnode, oldmetadata)
	end,
	
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-2/8, -2/8, -4/8,  2/8, 2/8, 4/8},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = { -1/4, -1/4, -1/2,  1/4, 1/4, 1/2 },
	},
	collision_box = {
		type = "fixed",
		fixed = { -1/4, -1/4, -1/2,  1/4, 1/4, 1/2 },
	},
	on_rotate = screwdriver.disallow,
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {choppy=2, cracky=3},
	sounds = default.node_sound_wood_defaults(),
	on_blast = ON_BLAST("tubelib:tubeS"),
})

minetest.register_node("tubelib:tubeA", {
	description = S("Tubelib Tube"),
	tiles = { -- Top, base, right, left, front, back
		"tubelib_knee2.png",
		"tubelib_hole2.png^[transformR180",
		"tubelib_knee.png^[transformR270",
		"tubelib_knee.png",
		"tubelib_knee2.png",
		"tubelib_hole2.png",
	},
	
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Tube:after_dig_tube(pos, oldnode, oldmetadata)
	end,
	
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-2/8, -4/8, -2/8,  2/8, 2/8,  2/8},
			{-2/8, -2/8, -4/8,  2/8, 2/8, -2/8},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = { -1/4, -1/2, -1/2,  1/4, 1/4, 1/4 },
	},
	collision_box = {
		type = "fixed",
		fixed = { -1/4, -1/2, -1/2,  1/4, 1/4, 1/4 },
	},
	on_rotate = screwdriver.disallow,
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {choppy=2, cracky=3, not_in_creative_inventory=1},
	sounds = default.node_sound_wood_defaults(),
	drop = "tubelib:tubeS",
	on_blast = ON_BLAST("tubelib:tubeA"),
})

minetest.register_craft({
	output = "tubelib:tubeS 4",
	recipe = {
		{"default:steel_ingot", "", "group:wood"},
		{"", "group:wood", ""},
		{"group:wood", "", "default:tin_ingot"},
	},
})
