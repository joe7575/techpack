--[[

	SmartLine
	=========

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	signaltower.lua:

]]--

-- Load support for I18n
local S = smartline.S

local function switch_on(pos, node, color)
	local meta = minetest.get_meta(pos)
	meta:set_string("state", color)
	node.name = "smartline:signaltower_"..color
	minetest.swap_node(pos, node)
end	

local function switch_off(pos, node)
	local meta = minetest.get_meta(pos)
	meta:set_string("state", "off")
	node.name = "smartline:signaltower"
	minetest.swap_node(pos, node)
end	

minetest.register_node("smartline:signaltower", {
	description = S("SmartLine Signal Tower"),
	tiles = {
		'smartline_signaltower_top.png',
		'smartline_signaltower_top.png',
		'smartline_signaltower.png',
	},

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -5/32, -16/32, -5/32,  5/32,  16/32, 5/32},
		},
	},
	
	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "smartline:signaltower")
		local meta = minetest.get_meta(pos)
		meta:set_string("state", "off")
		meta:set_string("infotext", S("SmartLine Signal Tower").." "..number)
	end,

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_on(pos, node, "green")
		end
	end,

	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,

	paramtype = "light",
	light_source = 0,	
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_glass_defaults(),
})

for _,color in ipairs({"green", "amber", "red"}) do
	minetest.register_node("smartline:signaltower_"..color, {
		description = S("SmartLine Signal Tower"),
		tiles = {
			'smartline_signaltower_top.png',
			'smartline_signaltower_top.png',
			'smartline_signaltower_'..color..'.png',
		},

		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{ -5/32, -16/32, -5/32,  5/32,  16/32, 5/32},
			},
		},
		on_rightclick = function(pos, node, clicker)
			if not minetest.is_protected(pos, clicker:get_player_name()) then
				switch_off(pos, node)
			end
		end,

		paramtype = "light",
		light_source = 10,	
		sunlight_propagates = true,
		paramtype2 = "facedir",
		groups = {crumbly=0, not_in_creative_inventory=1},
		is_ground_content = false,
		sounds = default.node_sound_glass_defaults(),
		drop = "smartline:signaltower",
	})
end

minetest.register_craft({
	output = "smartline:signaltower",
	recipe = {
		{"dye:red",    "default:copper_ingot", ""},
		{"dye:orange", "default:glass", ""},
		{"dye:green",  "tubelib:wlanchip", ""},
	},
})

tubelib.register_node("smartline:signaltower", {
	"smartline:signaltower_green", 
	"smartline:signaltower_amber", 
	"smartline:signaltower_red"}, {
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "green" then
			switch_on(pos, node, "green")
		elseif topic == "amber" then
			switch_on(pos, node, "amber")
		elseif topic == "red" then
			switch_on(pos, node, "red")
		elseif topic == "off" then
			switch_off(pos, node)
		elseif topic == "state" then
			local meta = minetest.get_meta(pos)
			return meta:get_string("state")
		end
	end,
})		
