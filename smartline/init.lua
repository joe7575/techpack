--[[

	SmartLine
	=========
	
	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	2018-01-01  v0.01  first version
	2018-01-26  v0.02  timer and sequencer added
	2018-02-01  v0.03  further commands, hints and cancel button aded

]]--

if minetest.get_modpath("display_lib") and display_lib ~= nil and
				minetest.get_modpath("font_lib") and font_lib ~= nil then
	dofile(minetest.get_modpath("smartline") .. "/playerdetector.lua")
end
dofile(minetest.get_modpath("smartline") .. "/button.lua")
dofile(minetest.get_modpath("smartline") .. "/signaltower.lua")
dofile(minetest.get_modpath("smartline") .. "/display.lua")
dofile(minetest.get_modpath("smartline") .. "/sequencer.lua")
dofile(minetest.get_modpath("smartline") .. "/timer.lua")
dofile(minetest.get_modpath("smartline") .. "/repeater.lua")
dofile(minetest.get_modpath("smartline") .. "/controller.lua")
dofile(minetest.get_modpath("smartline") .. "/commands.lua")