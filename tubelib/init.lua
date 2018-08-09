--[[

	Tube Library
	============

	Copyright (C) 2017,2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	2017-09-08  v0.01  first version
	2017-09-12  v0.02  bugfix in tubelib.get_pos() and others
	2017-09-21  v0.03  function get_num_items added
	2017-09-26  v0.04  param side added, node blackhole added
	2017-10-06  v0.05  Parameter 'player_name' added, furnace fuel detection changed
	2017-10-08  v0.06  tubelib.get_node_number() added, tubelib.version added
	2017-10-29  v0.07  Pusher bugfix, commands start/stop replaced by on/off
	2017-11-02  v0.08  Data base changed, aging of node positions added
	2017-11-04  v0.09  functions set_data/get_data added
	2018-01-27  v0.10  WLAN Chip added, recipes reviced, Pusher state 'blocked' added, 
                       function send_request changed
	2018-08-09  v1.00  Extracted from TechPack to be used as standalone mod
	                   - new tubing algorithm
	                   - tubelib.pull_stack()/tubelib.get_stack() added
	                   - item counter for pusher/distributor added
	
]]--


tubelib = {
	NodeDef = {},		-- node registration info
}

tubelib.version = 1.00


--------------------------- conversion to v0.04
minetest.register_lbm({
	label = "[Tubelib] Distributor update",
	name = "tubelib:update",
	nodenames = {"tubelib:distributor", "tubelib:distributor_active"},
	run_at_every_load = false,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		if minetest.deserialize(meta:get_string("filter")) == nil then
			local filter = {false,false,false,false}
			meta:set_string("filter", minetest.serialize(filter))
		end
		local inv = meta:get_inventory()
		inv:set_size('yellow', 6)
		inv:set_size('green', 6)
		inv:set_size('red', 6)
		inv:set_size('blue', 6)
	end
})

--------------------------- conversion to v0.10
minetest.register_lbm({
	label = "[Tubelib] Button update",
	name = "tubelib:update2",
	nodenames = {"tubelib:button", "tubelib:button_active"},
	run_at_every_load = false,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		local number = meta:get_string("number")
		if number ~= "" then
			meta:set_string("numbers", number)
			meta:set_string("number", nil)
		end
	end
})

minetest.register_craftitem("tubelib:wlanchip", {
	description = "Tubelib WLAN Chip",
	inventory_image = "tubelib_wlanchip.png",
})


minetest.register_craft({
	output = "tubelib:wlanchip 8",
	recipe = {
		{"default:mese_crystal", "default:copper_ingot", ""},
		{"default:gold_ingot",   "default:glass",	""},
		{"", "", ""},
	},
})


dofile(minetest.get_modpath("tubelib") .. "/tubes1.lua")
dofile(minetest.get_modpath("tubelib") .. "/tubes2.lua")
dofile(minetest.get_modpath("tubelib") .. "/command.lua")
dofile(minetest.get_modpath("tubelib") .. "/states.lua")
dofile(minetest.get_modpath("tubelib") .. "/pusher.lua")
dofile(minetest.get_modpath("tubelib") .. "/blackhole.lua")
dofile(minetest.get_modpath("tubelib") .. "/button.lua")
dofile(minetest.get_modpath("tubelib") .. "/lamp.lua")
dofile(minetest.get_modpath("tubelib") .. "/distributor.lua")
dofile(minetest.get_modpath("tubelib") .. "/legacy_nodes.lua")

