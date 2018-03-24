--[[

	SmartLine
	=========
	
	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

if minetest.get_modpath("display_lib") and display_lib ~= nil and
				minetest.get_modpath("font_lib") and font_lib ~= nil then
	dofile(minetest.get_modpath("smartline") .. "/display.lua")
end
dofile(minetest.get_modpath("smartline") .. "/button.lua")
dofile(minetest.get_modpath("smartline") .. "/signaltower.lua")
dofile(minetest.get_modpath("smartline") .. "/playerdetector.lua")
dofile(minetest.get_modpath("smartline") .. "/sequencer.lua")
dofile(minetest.get_modpath("smartline") .. "/timer.lua")
dofile(minetest.get_modpath("smartline") .. "/repeater.lua")
dofile(minetest.get_modpath("smartline") .. "/controller.lua")
dofile(minetest.get_modpath("smartline") .. "/commands.lua")