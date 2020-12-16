--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

]]--

tubelib_addons1 = {}

-- Load support for I18n
tubelib_addons1.S = minetest.get_translator("tubelib_addons1")

dofile(minetest.get_modpath("tubelib_addons1") .. "/quarry.lua")
dofile(minetest.get_modpath("tubelib_addons1") .. "/grinder.lua")
dofile(minetest.get_modpath("tubelib_addons1") .. "/nodes.lua")
dofile(minetest.get_modpath("tubelib_addons1") .. '/autocrafter.lua')
dofile(minetest.get_modpath("tubelib_addons1") .. '/harvester.lua')
dofile(minetest.get_modpath("tubelib_addons1") .. '/fermenter.lua')
dofile(minetest.get_modpath("tubelib_addons1") .. '/reformer.lua')
dofile(minetest.get_modpath("tubelib_addons1") .. '/funnel.lua')
dofile(minetest.get_modpath("tubelib_addons1") .. "/pusher_fast.lua")
dofile(minetest.get_modpath("tubelib_addons1") .. "/detector.lua")
dofile(minetest.get_modpath("tubelib_addons1") .. '/chest.lua')
dofile(minetest.get_modpath("tubelib_addons1") .. '/liquidsampler.lua')
dofile(minetest.get_modpath("tubelib_addons1") .. '/lbms.lua')
