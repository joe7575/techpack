--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017,2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

local cobble_generator_enabled = 
		tonumber(minetest.setting_get("tubelib_addons1_cobble_generator_enabled")) or true

if not cobble_generator_enabled then
	-- Replace default:stone with tubelib_addons1:basalt which is useless.
	default.cool_lava = function(pos, node)
		if node.name == "default:lava_source" then
			minetest.set_node(pos, {name = "default:obsidian"})
		else -- Lava flowing
			minetest.set_node(pos, {name = "tubelib_addons1:basalt"})
		end
		minetest.sound_play("default_cool_lava",
			{pos = pos, max_hear_distance = 16, gain = 0.25})
	end

	minetest.register_node("tubelib_addons1:basalt", {
		description = "Basalt",
		tiles = {"default_obsidian.png^[brighten"},
		groups = {cracky = 3, stone = 1},
		drop = 'default:cobble',
		sounds = default.node_sound_stone_defaults(),
	})
end


dofile(minetest.get_modpath("tubelib_addons1") .. "/nodes.lua")
dofile(minetest.get_modpath("tubelib_addons1") .. "/quarry.lua")
dofile(minetest.get_modpath("tubelib_addons1") .. "/grinder.lua")
dofile(minetest.get_modpath("tubelib_addons1") .. '/autocrafter.lua')
dofile(minetest.get_modpath("tubelib_addons1") .. '/harvester.lua')
dofile(minetest.get_modpath("tubelib_addons1") .. '/fermenter.lua')
dofile(minetest.get_modpath("tubelib_addons1") .. '/reformer.lua')
dofile(minetest.get_modpath("tubelib_addons1") .. '/funnel.lua')
dofile(minetest.get_modpath("tubelib_addons1") .. "/pusher_fast.lua")
dofile(minetest.get_modpath("tubelib_addons1") .. "/detector.lua")
dofile(minetest.get_modpath("tubelib_addons1") .. '/chest.lua')
dofile(minetest.get_modpath("tubelib_addons1") .. '/liquidsampler.lua')