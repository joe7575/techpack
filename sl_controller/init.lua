--[[

	sl_controller
	=============
	
	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

]]--

sl_controller = {}

dofile(minetest.get_modpath("sl_controller") .. "/config.lua")
dofile(minetest.get_modpath("sl_controller") .. "/controller.lua")
dofile(minetest.get_modpath("sl_controller") .. "/commands.lua")
dofile(minetest.get_modpath("sl_controller") .. "/battery.lua")
dofile(minetest.get_modpath("sl_controller") .. "/server.lua")
dofile(minetest.get_modpath("sl_controller") .. "/terminal.lua")
