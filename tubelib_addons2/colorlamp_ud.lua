--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	colorlamp_ud.lua which requires the mod unifieddyes:
	
]]--

-- Load support for I18n
local S = tubelib_addons2.S

local function switch_on(pos, node, player)
	if player == nil or not minetest.is_protected(pos, player:get_player_name()) then
		node.name = "tubelib_addons2:lamp_on"
		minetest.swap_node(pos, node)
	end
end	

local function switch_off(pos, node, player)
	if player == nil or not minetest.is_protected(pos, player:get_player_name()) then
		node.name = "tubelib_addons2:lamp_off"
		minetest.swap_node(pos, node)
	end
end	

minetest.register_node("tubelib_addons2:lamp_off", {
	description = S("Tubelib Color Lamp"),
	tiles = {"tubelib_addons2_lamp.png^[colorize:#000000:100"},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local number = tubelib.add_node(pos, "tubelib_addons2:lamp_off")
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Tubelib Color Lamp").." "..number)
		unifieddyes.recolor_on_place(pos, placer, itemstack, pointed_thing)
	end,

	on_rightclick = switch_on,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		tubelib.remove_node(pos)
		unifieddyes.after_dig_node(pos, oldnode, oldmetadata, digger)
	end,

	on_construct = unifieddyes.on_construct,
	on_dig = unifieddyes.on_dig,
	
	paramtype = "light",
	paramtype2 = "color",
	palette = "unifieddyes_palette_extended.png",
	place_param2 = 241,
	sunlight_propagates = true,
	sounds = default.node_sound_stone_defaults(),
	groups = {choppy=2, cracky=1, ud_param2_colorable = 1},
	is_ground_content = false,
	drop = "tubelib_addons2:lamp_off"
})


minetest.register_node("tubelib_addons2:lamp_on", {
	description = S("Tubelib Color Lamp"),
	tiles = {"tubelib_addons2_lamp.png"},

	on_rightclick = switch_off,

	paramtype = "light",
	paramtype2 = "color",
	palette = "unifieddyes_palette_extended.png",
	sounds = default.node_sound_stone_defaults(),
	groups = {choppy=2, cracky=1, not_in_creative_inventory=1, ud_param2_colorable = 1},
	
	on_construct = unifieddyes.on_construct,
	after_place_node = unifieddyes.recolor_on_place,
	
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		tubelib.remove_node(pos)
		unifieddyes.after_dig_node(pos, oldnode, oldmetadata, digger)
	end,
   
	on_dig = unifieddyes.on_dig,
	light_source = minetest.LIGHT_MAX,	
	is_ground_content = false,
	drop = "tubelib_addons2:lamp_off"
})

tubelib.register_node("tubelib_addons2:lamp_off", {"tubelib_addons2:lamp_on"}, {
	on_recv_message = function(pos, topic, payload)
		if topic == "on" then
			local node = minetest.get_node(pos)
			switch_on(pos, node, nil)
		elseif topic == "off" then
			local node = minetest.get_node(pos)
			switch_off(pos, node, nil)
		end
	end,
})	

minetest.register_craft({
	type = "shapeless",
	output = "tubelib_addons2:lamp_off",
	recipe = {"tubelib:lamp"},
})


--
-- Convert legacy nodes
--
for idx=1,12 do
	minetest.register_node("tubelib_addons2:lamp"..idx, {
		description = S("Tubelib Color Lamp").." "..idx,
		tiles = {"tubelib_addons2_lamp.png"},
		paramtype = 'light',
		groups = {choppy=2, cracky=1, not_in_creative_inventory=1},
		is_ground_content = false,
		drop = "tubelib_addons2:lamp_off"
	})
end


minetest.register_lbm({
	label = "[Tubelib] Color Lamp update",
	name = "tubelib_addons2:update",
	nodenames = {
		"tubelib_addons2:lamp",
		"tubelib_addons2:lamp1", "tubelib_addons2:lamp2", "tubelib_addons2:lamp3", 
		"tubelib_addons2:lamp4", "tubelib_addons2:lamp5", "tubelib_addons2:lamp6", 
		"tubelib_addons2:lamp7", "tubelib_addons2:lamp8", "tubelib_addons2:lamp9", 
		"tubelib_addons2:lamp10", "tubelib_addons2:lamp11", "tubelib_addons2:lamp12", 
	},
	run_at_every_load = true,
	action = function(pos, node)
		local color = {112, 108, 104, 100, 96, 115, 240, 255, 80, 120, 99, 20}
		local meta = minetest.get_meta(pos)
		local num = meta:get_int("color")
		if node.name == "tubelib_addons2:lamp" then
			node.param2 = color[tonumber(num)]
			node.name = "tubelib_addons2:lamp_off"
		else
			node.param2 = color[tonumber(num)]
			node.name = "tubelib_addons2:lamp_on"
		end
		minetest.swap_node(pos, node)
		local number = meta:get_int("number") or 0
		number = string.format("%.04u", number)
		meta:set_string("infotext", S("Tubelib Color Lamp").." "..number)
	end
})

