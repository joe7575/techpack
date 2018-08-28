--[[

	SmartLine
	=========
	
	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

smartline = {}

local MP = minetest.get_modpath("smartline")

if minetest.get_modpath("display_lib") and display_lib ~= nil and
				minetest.get_modpath("font_lib") and font_lib ~= nil then
	dofile(MP.."/display.lua")
end
dofile(MP.."/button.lua")
dofile(MP.."/signaltower.lua")
dofile(MP.."/playerdetector.lua")
dofile(MP.."/sequencer.lua")
dofile(MP.."/timer.lua")
dofile(MP.."/repeater.lua")
dofile(MP.."/controller.lua")
dofile(MP.."/commands.lua")
-- ICTA Controller
dofile(MP.."/icta/submenu.lua")
dofile(MP.."/icta/condition.lua")
dofile(MP.."/icta/action.lua")
dofile(MP.."/icta/formspec.lua")
dofile(MP.."/icta/controller.lua")
dofile(MP.."/icta/commands.lua")
dofile(MP.."/icta/edit.lua")
dofile(MP.."/icta/battery.lua")
dofile(MP.."/icta/balancer.lua")
