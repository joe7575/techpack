--[[

	Tubelib Addons 3
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

]]--

tubelib_addons3 = {}

-- Load support for I18n
tubelib_addons3.S = minetest.get_translator("tubelib_addons3")

dofile(minetest.get_modpath("tubelib_addons3") .. '/chest.lua')
dofile(minetest.get_modpath("tubelib_addons3") .. '/pusher.lua')
dofile(minetest.get_modpath("tubelib_addons3") .. '/distributor.lua')
dofile(minetest.get_modpath("tubelib_addons3") .. '/pushing_chest.lua')
dofile(minetest.get_modpath("tubelib_addons3") .. '/teleporter.lua')
dofile(minetest.get_modpath("tubelib_addons3") .. '/funnel.lua')

if minetest.global_exists("minecart") then
	dofile(minetest.get_modpath("tubelib_addons3") .. '/chest_cart.lua')
end
