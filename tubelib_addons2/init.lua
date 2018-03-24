--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017,2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

dofile(minetest.get_modpath("tubelib_addons2") .. "/timer.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/sequencer.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/gateblock.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/doorblock.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/colorlamp.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/repeater.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/programmer.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/accesscontrol.lua")
if mesecon then
	dofile(minetest.get_modpath("tubelib_addons2") .. "/mesecons_converter.lua")
end
