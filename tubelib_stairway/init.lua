minetest.register_node("tubelib_stairway:bridge1", {
	description = "Tubelib Bridge 1",
	tiles = {
		'tubelib_stairway_bottom.png',
		'tubelib_stairway_bottom.png',
		'tubelib_stairway_side.png',
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ 15/32, -17/32, -17/32,  17/32,  17/32, 17/32},
			{-17/32, -17/32, -17/32, -15/32,  17/32, 17/32},
			{-17/32, -15/32, -17/32,  17/32, -14/32, 17/32}
		},
	},

	selection_box = {
		type = "fixed",
		fixed = {
			{-16/32, -18/32, -16/32,  16/32, -12/32, 16/32},
		},
	},
	
	--climbable = true,
	paramtype2 = "facedir",
	paramtype = "light",
	sunlight_propagates = true,
	use_texture_alpha = true,
	is_ground_content = false,
	groups = {cracky = 2},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("tubelib_stairway:bridge2", {
	description = "Tubelib Bridge 2",
	tiles = {
		'tubelib_stairway_bottom.png',
		'tubelib_stairway_bottom.png',
		'tubelib_stairway_side.png',
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-17/32, -17/32, -17/32, -15/32,  17/32, 17/32},
			{-17/32, -15/32, -17/32,  17/32, -14/32, 17/32}
		},
	},

	selection_box = {
		type = "fixed",
		fixed = {
			{-16/32, -18/32, -16/32,  16/32, -12/32, 16/32},
		},
	},
	
	--climbable = true,
	paramtype2 = "facedir",
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 2},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("tubelib_stairway:bridge3", {
	description = "Tubelib Bridge 3",
	tiles = {
		'tubelib_stairway_bottom.png',
		'tubelib_stairway_bottom.png',
		'tubelib_stairway_side.png',
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-17/32, -17/32,  15/32,  17/32,  17/32, 17/32},
			{ 15/32, -17/32, -17/32,  17/32,  17/32, 17/32},
			{-17/32, -17/32, -17/32, -15/32,  17/32, 17/32},
			{-17/32, -15/32, -17/32,  17/32, -14/32, 17/32}
		},
	},

	selection_box = {
		type = "fixed",
		fixed = {
			{-16/32, -18/32, -16/32,  16/32, -12/32, 16/32},
		},
	},
	
	--climbable = true,
	paramtype2 = "facedir",
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 2},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("tubelib_stairway:bridge4", {
	description = "Tubelib Bridge 4",
	tiles = {
		'tubelib_stairway_bottom.png',
		'tubelib_stairway_bottom.png',
		'tubelib_stairway_side.png',
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-17/32, -17/32,  15/32,  17/32,  17/32, 17/32},
			{-17/32, -17/32, -17/32, -15/32,  17/32, 17/32},
			{-17/32, -15/32, -17/32,  17/32, -14/32, 17/32}
		},
	},

	selection_box = {
		type = "fixed",
		fixed = {
			{-16/32, -18/32, -16/32,  16/32, -12/32, 16/32},
		},
	},
	
	--climbable = true,
	paramtype2 = "facedir",
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 2},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("tubelib_stairway:bridge5", {
	description = "Tubelib Bridge 5",
	tiles = {
		'tubelib_stairway_bottom.png',
		'tubelib_stairway_bottom.png',
		'tubelib_stairway_side.png',
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-17/32, -15/32, -17/32,  17/32, -14/32, 17/32}
		},
	},

	selection_box = {
		type = "fixed",
		fixed = {
			{-16/32, -18/32, -16/32,  16/32, -12/32, 16/32},
		},
	},
	
	--climbable = true,
	paramtype2 = "facedir",
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 2},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("tubelib_stairway:stairway", {
	description = "Tubelib Stairway",
	tiles = {
		'tubelib_stairway_steps.png',
		'tubelib_stairway_steps.png',
		'tubelib_stairway_side.png',
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ 15/32, -1/32,  -1/32,  17/32,  49/32, 17/32},
			{-17/32, -1/32,  -1/32, -15/32,  49/32, 17/32},
			{-17/32, -1/32,  -1/32,  17/32,   1/32, 17/32},
			
			{ 15/32, -17/32, -17/32,  17/32,  33/32, 1/32},
			{-17/32, -17/32, -17/32, -15/32,  33/32, 1/32},
			{-17/32, -17/32, -17/32,  17/32, -15/32, 1/32},
		},
	},

	selection_box = {
		type = "fixed",
		fixed = {
			{-16/32, -18/32, -16/32,  16/32, -12/32,  0/32},
			{-16/32, -18/32,   0/32,  16/32,   2/32, 16/32},
		},
	},
		
	--climbable = true,
	paramtype2 = "facedir",
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 2},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("tubelib_stairway:ladder1", {
	description = "Tubelib Ladder 1",
	tiles = {
		'tubelib_stairway_steps.png',
		'tubelib_stairway_steps.png',
		'tubelib_stairway_ladder.png',
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-17/32, -17/32,  15/32,  17/32,  17/32,  17/32},
			{-17/32, -17/32, -17/32, -15/32,  17/32,  17/32},
			{-17/32, -17/32, -17/32,  17/32,  17/32, -15/32},
			{ 15/32, -17/32, -17/32,  17/32,  17/32,  17/32},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -8/16,  8/16, 8/16, 8/16},
	},

	climbable = true,
	paramtype2 = "facedir",
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 2},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("tubelib_stairway:ladder2", {
	description = "Tubelib Ladder 2",
	tiles = {
		'tubelib_stairway_steps.png',
		'tubelib_stairway_steps.png',
		'tubelib_stairway_ladder.png',
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-17/32, -17/32,  15/32,  17/32,  17/32,  17/32},
			{-17/32, -17/32, -17/32, -15/32,  17/32,  17/32},
			--{-17/32, -17/32, -17/32,  17/32,  17/32, -15/32},
			{ 15/32, -17/32, -17/32,  17/32,  17/32,  17/32},
		},
	},

	selection_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -8/16,  8/16, 8/16, 8/16},
	},
	
	climbable = true,
	paramtype2 = "facedir",
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 2},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("tubelib_stairway:lattice", {
	description = "Tubelib Lattice",
	tiles = {
		'tubelib_stairway_lattice.png',
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-8/16, -8/16, -8/16, -7/16,  8/16,  8/16},
			{ 7/16, -8/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16, -8/16, -8/16,  8/16, -7/16,  8/16},
			{-8/16,  7/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16, -8/16, -8/16,  8/16,  8/16, -7/16},
			{-8/16, -8/16,  7/16,  8/16,  8/16,  8/16},
		},
	},

	selection_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -8/16,  8/16, 8/16, 8/16},
	},
	
	paramtype2 = "facedir",
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 2},
	sounds = default.node_sound_metal_defaults(),
})


minetest.register_craft({
	output = "tubelib_stairway:bridge1 2",
	recipe = {
		{"", "", ""},
		{"dye:dark_grey", "", "default:coal_lump"},
		{"default:steel_ingot", "default:tin_ingot", "default:steel_ingot"},
	},
})

minetest.register_craft({
	output = "tubelib_stairway:bridge3 2",
	recipe = {
		{"", "", ""},
		{"default:coal_lump", "", "dye:dark_grey"},
		{"default:steel_ingot", "default:tin_ingot", "default:steel_ingot"},
	},
})

minetest.register_craft({
	output = "tubelib_stairway:stairway 2",
	recipe = {
		{"", "", "default:steel_ingot"},
		{"dye:dark_grey", "default:tin_ingot", "default:coal_lump"},
		{"default:steel_ingot", "", ""},
	},
})

minetest.register_craft({
	output = "tubelib_stairway:ladder1 2",
	recipe = {
		{"", "default:steel_ingot", ""},
		{"dye:dark_grey", "default:tin_ingot", "default:coal_lump"},
		{"", "default:steel_ingot", ""},
	},
})

minetest.register_craft({
	output = "tubelib_stairway:lattice 2",
	recipe = {
		{"default:steel_ingot", "", "default:steel_ingot"},
		{"dye:dark_grey", "default:tin_ingot", "default:coal_lump"},
		{"default:steel_ingot", "", "default:steel_ingot"},
	},
})

minetest.register_craft({
	output = "tubelib_stairway:ladder2",
	recipe = {{"tubelib_stairway:ladder1"}},
})

minetest.register_craft({
	output = "tubelib_stairway:bridge2",
	recipe = {{"tubelib_stairway:bridge1"}},
})

minetest.register_craft({
	output = "tubelib_stairway:bridge4",
	recipe = {{"tubelib_stairway:bridge3"}},
})

minetest.register_craft({
	output = "tubelib_stairway:bridge5",
	recipe = {{"tubelib_stairway:bridge4"}},
})
