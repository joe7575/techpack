--[[

	SaferLua [safer_lua]
	====================

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	environ.lua:

]]--

safer_lua = {}

dofile(minetest.get_modpath("safer_lua") .. "/data_struct.lua")
dofile(minetest.get_modpath("safer_lua") .. "/scanner.lua")
dofile(minetest.get_modpath("safer_lua") .. "/environ.lua")