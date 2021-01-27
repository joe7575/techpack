--[[

	Tube Library
	============

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
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
	2018-12-21  v2.00  Switch to tubelib2, "defect" nodes and "Repair Kit" added,
                       Forceload block added, Basalt as Cobble Stone alternative added
	
]]--


tubelib = {
	NodeDef = {},		-- node registration info
}

-- Load support for I18n
tubelib.S = minetest.get_translator("tubelib")
local S = tubelib.S

tubelib.version = 2.00

tubelib.max_num_forceload_blocks = tonumber(minetest.setting_get("tubelib_max_num_forceload_blocks")) or 10
tubelib.basalt_stone_enabled = minetest.setting_get("tubelib_basalt_stone_enabled") == "true"
tubelib.machine_aging_value = tonumber(minetest.setting_get("tubelib_machine_aging_value")) or 100


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
	description = S("Tubelib WLAN Chip"),
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


if tubelib2.version < 2.0 then
	error("TechPack/Tubelib requires tubelib2 version 2.0 or newer!!!")
else
	dofile(minetest.get_modpath("tubelib") .. "/tubes.lua")
	dofile(minetest.get_modpath("tubelib") .. "/command.lua")
	-- conversion from v1.16 to v2.00
	dofile(minetest.get_modpath("tubelib") .. "/migrate.lua")
	dofile(minetest.get_modpath("tubelib") .. "/states.lua")
	dofile(minetest.get_modpath("tubelib") .. "/defect.lua")
	dofile(minetest.get_modpath("tubelib") .. "/node_states.lua")
	dofile(minetest.get_modpath("tubelib") .. "/pusher.lua")
	dofile(minetest.get_modpath("tubelib") .. "/blackhole.lua")
	dofile(minetest.get_modpath("tubelib") .. "/button.lua")
	dofile(minetest.get_modpath("tubelib") .. "/lamp.lua")
	dofile(minetest.get_modpath("tubelib") .. "/distributor.lua")
	dofile(minetest.get_modpath("tubelib") .. "/legacy_nodes.lua")
	dofile(minetest.get_modpath("tubelib") .. "/repairkit.lua")
	dofile(minetest.get_modpath("tubelib") .. "/mark.lua")
	dofile(minetest.get_modpath("tubelib") .. "/forceload.lua")
	dofile(minetest.get_modpath("tubelib") .. "/basalt.lua")
end
