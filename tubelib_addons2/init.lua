--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	2017-10-05  v0.01  first version
	2017-10-06  v0.02  Timer added
	2017-10-08  v0.03  Repeater added
	2017-10-08  v0.04  Mesecons Converter and Programmer Tool added
	2017-10-16  v0.05  Color Lamp added
	2017-10-29  v0.06  WLAN Chip + Access Lock added, recipes changed
	2017-10-29  v0.07  WLAN Chip removed, recipes changed

]]--



if tubelib.version >= 0.10 then
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
else
	print("[Tubelib] Version 0.10+ of Tubelib Mod is required!")
end