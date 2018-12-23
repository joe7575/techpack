--[[

	Tube Library
	============

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	basalt.lua:
	
]]--

if tubelib.basalt_stone_enabled then
	-- Replace default:stone with tubelib:basalt which is useless for ore generation.
	default.cool_lava = function(pos, node)
		if node.name == "default:lava_source" then
			minetest.set_node(pos, {name = "default:obsidian"})
		else -- Lava flowing
			minetest.set_node(pos, {name = "tubelib:basalt_stone"})
		end
		minetest.sound_play("default_cool_lava",
			{pos = pos, max_hear_distance = 16, gain = 0.25})
	end

	minetest.register_node("tubelib:basalt_stone", {
		description = "Basalt Stone",
		tiles = {"default_stone.png^[brighten"},
		groups = {cracky = 3, stone = 1},
		drop = "default:silver_sand",
		sounds = default.node_sound_stone_defaults(),
	})
	minetest.register_node("tubelib:basalt_stone_brick", {
		description = "Basalt Stone Brick",
		paramtype2 = "facedir",
		place_param2 = 0,
		tiles = {"default_stone_brick.png^[brighten"},
		is_ground_content = false,
		groups = {cracky = 2, stone = 1},
		sounds = default.node_sound_stone_defaults(),
	})

	minetest.register_node("tubelib:basalt_stone_block", {
		description = "Basalt Stone Block",
		tiles = {"default_stone_block.png^[brighten"},
		is_ground_content = false,
		groups = {cracky = 2, stone = 1},
		sounds = default.node_sound_stone_defaults(),
	})

	minetest.register_craft({
		output = "tubelib:basalt_stone_brick 4",
		recipe = {
			{"tubelib:basalt_stone", "tubelib:basalt_stone"},
			{"tubelib:basalt_stone", "tubelib:basalt_stone"},
		}
	})

	minetest.register_craft({
		output = "tubelib:basalt_stone_block 9",
		recipe = {
			{"tubelib:basalt_stone", "tubelib:basalt_stone", "tubelib:basalt_stone"},
			{"tubelib:basalt_stone", "tubelib:basalt_stone", "tubelib:basalt_stone"},
			{"tubelib:basalt_stone", "tubelib:basalt_stone", "tubelib:basalt_stone"},
		}
	})
end
