--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	industriallamp.lua:
	
]]--

-- Load support for I18n
local S = tubelib_addons2.S

local function switch_on(pos, node)
	if string.sub(node.name, -3) ~= "_on" then
		node.name = node.name.."_on"
		minetest.swap_node(pos, node)
	end
end	

local function switch_off(pos, node)
	if string.sub(node.name, -3) == "_on" then
		node.name = string.sub(node.name, 1, -4)
		minetest.swap_node(pos, node)
		local pos1 = {x=pos.x-5, y=pos.y-5, z=pos.z-5}
		local pos2 = {x=pos.x+5, y=pos.y+5, z=pos.z+5}
		minetest.fix_light(pos1, pos2)
	end
end	

local function register_lamp(tbl)
	local num, tiles, tiles_on, node_box, size = tbl.num, tbl.tiles, tbl.tiles_on, tbl.node_box, tbl.size
	minetest.register_node("tubelib_addons2:industriallamp"..num, {
		description = S("Tubelib Industrial Lamp").." "..num,
		tiles = tiles,
		drawtype = "nodebox",
		node_box = node_box,
		inventory_image = 'tubelib_addons2_industriallamp_inv'..num..'.png',
		
		selection_box = {
			type = "wallmounted",
			wall_top =    {-size.x, 0.5 - size.y, -size.z, size.x, 0.5, size.z},
			wall_bottom = {-size.x, -0.5, -size.z, size.x, -0.5 + size.y, size.z},
			wall_side =   {-0.5, -size.z, size.x, -0.5 + size.y, size.z, -size.x},
		},
	
		after_place_node = function(pos, placer)
			local number = tubelib.add_node(pos, "tubelib_addons2:industriallamp"..num)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", S("Tubelib Industrial Lamp").." "..num..": "..number)
		end,

		on_rightclick = function(pos, node, clicker)
			if not minetest.is_protected(pos, clicker:get_player_name()) then
				node.name = "tubelib_addons2:industriallamp"..num.."_on"
				minetest.swap_node(pos, node)
			end
		end,

		after_dig_node = function(pos)
			tubelib.remove_node(pos)
		end,

		paramtype = "light",
		light_source = 0,	
		sunlight_propagates = true,
		paramtype2 = "wallmounted",
		groups = {choppy=2, cracky=2, crumbly=2},
		is_ground_content = false,
		sounds = default.node_sound_glass_defaults(),
	})

	minetest.register_node("tubelib_addons2:industriallamp"..num.."_on", {
		description = S("Tubelib Industrial Lamp").." "..num,
		tiles = tiles_on,
		drawtype = "nodebox",
		node_box = node_box,
		
		selection_box = {
			type = "wallmounted",
			wall_top =    {-size.x, 0.5 - size.y, -size.z, size.x, 0.5, size.z},
			wall_bottom = {-size.x, -0.5, -size.z, size.x, -0.5 + size.y, size.z},
			wall_side =   {-0.5, -size.z, size.x, -0.5 + size.y, size.z, -size.x},
		},
	
		after_place_node = function(pos, placer)
			local number = tubelib.add_node(pos, "tubelib_addons2:industriallamp"..num)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", S("Tubelib Industrial Lamp").." "..num..": "..number)
		end,
		
		on_rightclick = function(pos, node, clicker)
			if not minetest.is_protected(pos, clicker:get_player_name()) then
				node.name = "tubelib_addons2:industriallamp"..num
				minetest.swap_node(pos, node)
				local pos1 = {x=pos.x-5, y=pos.y-5, z=pos.z-5}
				local pos2 = {x=pos.x+5, y=pos.y+5, z=pos.z+5}
				minetest.fix_light(pos1, pos2)
			end
		end,

		after_dig_node = function(pos)
			tubelib.remove_node(pos)
		end,

		paramtype = "light",
		light_source = minetest.LIGHT_MAX,	
		sunlight_propagates = true,
		paramtype2 = "wallmounted",
		groups = {choppy=2, cracky=2, crumbly=2, not_in_creative_inventory=1},
		drop = "tubelib_addons2:industriallamp"..num,
		is_ground_content = false,
		sounds = default.node_sound_glass_defaults(),
	})

	tubelib.register_node("tubelib_addons2:industriallamp"..num, {"tubelib_addons2:industriallamp"..num.."_on"}, {
		on_recv_message = function(pos, topic, payload)
			local node = minetest.get_node(pos)
			if topic == "on" then
				switch_on(pos, node)
			elseif topic == "off" then
				switch_off(pos, node)
			end
		end,
	})
end

minetest.register_craft({
	output = "tubelib_addons2:industriallamp1 2",
	recipe = {
		{"", "", ""},
		{"default:glass", "tubelib:wlanchip", "dye:grey"},
		{"basic_materials:plastic_strip", "default:copper_ingot", "basic_materials:plastic_strip"},
	},
})

minetest.register_craft({
	output = "tubelib_addons2:industriallamp2 2",
	recipe = {
		{"default:glass", "default:glass", ""},
		{"tubelib:wlanchip", "dye:black", ""},
		{"basic_materials:steel_bar", "basic_materials:steel_bar", ""},
	},
})


register_lamp({
	num = 1, 
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_addons2_industriallamp1.png',
		'tubelib_addons2_industriallamp1.png',
		'tubelib_addons2_industriallamp1.png^[transformR180',
		'tubelib_addons2_industriallamp1.png^[transformR180',
		'tubelib_addons2_industriallamp1.png',
		'tubelib_addons2_industriallamp1.png',
	},
	tiles_on = {
		-- up, down, right, left, back, front
		'tubelib_addons2_industriallamp1_on.png',
		'tubelib_addons2_industriallamp1_on.png',
		'tubelib_addons2_industriallamp1_on.png^[transformR180',
		'tubelib_addons2_industriallamp1_on.png^[transformR180',
		'tubelib_addons2_industriallamp1_on.png',
		'tubelib_addons2_industriallamp1_on.png',
	},
	node_box = {
		type = "fixed",
		fixed = {
			{-8/16,  -8/16, -3/32, -6/16,  -9/32,  3/32},
			{ 6/16,  -8/16, -3/32,  8/16,  -9/32,  3/32},
			{-6/16,  -7/16, -1/16,  6/16,  -5/16,  1/16},
		},
	},
	size = {x = 8/16, y = 7/32, z = 3/32}
})
	
register_lamp({
	num = 2, 
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_addons2_industriallamp2.png',
		'tubelib_addons2_industriallamp2.png',
		'tubelib_addons2_industriallamp2.png^[transformR180',
		'tubelib_addons2_industriallamp2.png^[transformR180',
		'tubelib_addons2_industriallamp2.png',
		'tubelib_addons2_industriallamp2.png',
	},
	tiles_on = {
		-- up, down, right, left, back, front
		'tubelib_addons2_industriallamp2_on.png',
		'tubelib_addons2_industriallamp2_on.png',
		'tubelib_addons2_industriallamp2_on.png^[transformR180',
		'tubelib_addons2_industriallamp2_on.png^[transformR180',
		'tubelib_addons2_industriallamp2_on.png',
		'tubelib_addons2_industriallamp2_on.png',
	},
	node_box = {
		type = "fixed",
		fixed = {
			{-8/32, -16/32, -4/32, 8/32, -9/32, 4/32},
			{-7/32, -16/32, -5/32, 7/32, -9/32, 5/32},
			{-7/32,  -9/32, -4/32, 7/32, -8/32, 4/32},
		},
	},
	size = {x = 8/32, y = 8/32, z = 5/32}
})
	