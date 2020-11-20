--[[

	sl_controller
	=============

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	battery.lua:
	
	REPLACED BY SMARTLINE BATTERY !!!

]]--

local function calc_percent(content)
	local val = (sl_controller.battery_capacity - 
			math.min(content or 0, sl_controller.battery_capacity))
	return 100 - math.floor((val * 100.0 / sl_controller.battery_capacity))
end

local function on_timer(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local percent = calc_percent(meta:get_int("content"))
	meta:set_string("infotext", "Battery ("..percent.."%)")
	if percent == 0 then
		local node = minetest.get_node(pos)
		node.name = "sl_controller:battery_empty"
		minetest.swap_node(pos, node)
		return false
	end
	return true
end

local function register_battery(ext, percent, nici)
	minetest.register_node("sl_controller:battery"..ext, {
		description = "Battery "..ext,
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
			meta:set_int("content", sl_controller.battery_capacity * percent)
			local node = minetest.get_node(pos)
			node.name = "sl_controller:battery"
			minetest.swap_node(pos, node)
			on_timer(pos, 1)
			minetest.get_node_timer(pos):start(30)
		end,
		
		on_timer = on_timer,
		
		
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			local percent = calc_percent(tonumber(oldmetadata.fields.content))
			local stack
			if percent > 95 then
				stack = ItemStack("smartline:battery")
			elseif percent > 75 then
				stack = ItemStack("smartline:battery75")
			elseif percent > 50 then
				stack = ItemStack("smartline:battery50")
			elseif percent > 25 then
				stack = ItemStack("smartline:battery25")
			else
				return
			end
			local inv = minetest.get_inventory({type="player", name=digger:get_player_name()})
			inv:add_item("main", stack)
		end,

		paramtype = "light",
		sunlight_propagates = true,
		paramtype2 = "facedir",
		groups = {choppy=1, cracky=1, crumbly=1, not_in_creative_inventory=nici},
		drop = "",
		is_ground_content = false,
		sounds = default.node_sound_stone_defaults(),
	})
end

register_battery("", 1.0, 1)
register_battery("75", 0.75, 1)
register_battery("50", 0.5, 1)
register_battery("25", 0.25, 1)

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
		meta:set_int("content", 0)
	end,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=1, cracky=1, crumbly=1, not_in_creative_inventory=1},
	drop = "",
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
})


--if minetest.global_exists("moreores") then
--	minetest.register_craft({
--		output = "sl_controller:battery 2",
--		recipe = {
--			{"", "moreores:silver_ingot", ""},
--			{"", "default:copper_ingot", ""},
--			{"", "moreores:silver_ingot", ""},
--		}
--	})
--else
--	minetest.register_craft({
--		output = "sl_controller:battery 2",
--		recipe = {
--			{"", "default:tin_ingot", ""},
--			{"", "default:copper_ingot", ""},
--			{"", "default:tin_ingot", ""},
--		}
--	})
--end
