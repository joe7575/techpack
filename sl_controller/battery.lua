--[[

	sl_controller
	=============

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	battery.lua:

]]--

local function on_timer(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local percent = (sl_controller.battery_capacity - meta:get_int("content"))
	percent = 100 - math.floor((percent * 100.0 / sl_controller.battery_capacity))
	print("percent", percent, meta:get_int("content"))
	meta:set_string("infotext", "Battery ("..percent.."%)")
	if percent == 0 then
		local node = minetest.get_node(pos)
		node.name = "sl_controller:battery_empty"
		minetest.swap_node(pos, node)
		return false
	end
	return true
end

minetest.register_node("sl_controller:battery", {
	description = "Battery",
	inventory_image = 'sl_controller_battery_inventory.png',
	wield_image = 'sl_controller_battery_inventory.png',
	tiles = {
		-- up, down, right, left, back, front
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png^sl_controller_battery_green.png",
	},

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -6/32, -6/32, 14/32,  6/32,  6/32, 16/32},
		},
	},
	
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_int("content", sl_controller.battery_capacity)
		minetest.get_node_timer(pos):start(2)
	end,
	
	on_timer = on_timer,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=1, cracky=1, crumbly=1},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("sl_controller:battery_empty", {
	description = "Battery",
	tiles = {
		-- up, down, right, left, back, front
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png^sl_controller_battery_red.png",
	},

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -6/32, -6/32, 14/32,  6/32,  6/32, 16/32},
		},
	},
	
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_int("content", nil)
	end,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=1, cracky=1, crumbly=1, not_in_creative_inventory=1},
	drop = "",
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
})


if minetest.global_exists("moreores") then
	minetest.register_craft({
		output = "sl_controller:battery 2",
		recipe = {
			{"", "moreores:silver_ingot", ""},
			{"", "default:copper_ingot", ""},
			{"", "moreores:silver_ingot", ""},
		}
	})
else
	minetest.register_craft({
		output = "sl_controller:battery 2",
		recipe = {
			{"", "default:tin_ingot", ""},
			{"", "default:copper_ingot", ""},
			{"", "default:tin_ingot", ""},
		}
	})
end
