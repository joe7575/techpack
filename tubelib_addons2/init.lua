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
dofile(minetest.get_modpath("tubelib_addons2") .. "/repeater.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/logic_not.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/programmer.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/accesscontrol.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/streetlamp.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/ceilinglamp.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/invisiblelamp.lua")
dofile(minetest.get_modpath("tubelib_addons2") .. "/industriallamp.lua")

if minetest.get_modpath("mesecons") and mesecon then
	dofile(minetest.get_modpath("tubelib_addons2") .. "/mesecons_converter.lua")
end
if minetest.get_modpath("unifieddyes") and unifieddyes then
	dofile(minetest.get_modpath("tubelib_addons2") .. "/colorlamp_ud.lua")
else
	dofile(minetest.get_modpath("tubelib_addons2") .. "/colorlamp.lua")
end
