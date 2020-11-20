--[[

	TechPack Warehouse
	==================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	init.lua

]]--

techpack_warehouse = {}

-- Load support for I18n
techpack_warehouse.S = minetest.get_translator("techpack_warehouse")


dofile(minetest.get_modpath("techpack_warehouse") .. "/common.lua")
dofile(minetest.get_modpath("techpack_warehouse") .. "/box_steel.lua")
dofile(minetest.get_modpath("techpack_warehouse") .. "/box_copper.lua")
dofile(minetest.get_modpath("techpack_warehouse") .. "/box_gold.lua")
