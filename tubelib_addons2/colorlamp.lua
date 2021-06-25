--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	colorlamp.lua:
	
]]--

-- Load support for I18n
local S = tubelib_addons2.S

local tColors = {"#0000FF", "#00FFFF", "#00FF00", "#FFFF00", "#FF0000", "#FF00FF",
                 "#FFFFFF", "#000000", "#3BC23B", "#CA3131", "#FFA500", "#FFC0CB"}
local sColor = "1,2,3,4,5,6,7,8,9,10,11,12"

local function switch_node(pos, num, player)
	if player == nil or not minetest.is_protected(pos, player:get_player_name()) then
		local meta = minetest.get_meta(pos)
		local node = minetest.get_node(pos)
		node.name = "tubelib_addons2:lamp"..num
		minetest.swap_node(pos, node)
		local number = meta:get_int("number")
		number = string.format("%.04u", number)
		meta:set_string("infotext", S("Tubelib Color Lamp").." "..number)
		if num ~= "" then
			meta:set_int("color", num)
		end
	end
end	

minetest.register_node("tubelib_addons2:lamp", {
	description = S("Tubelib Color Lamp"),
	tiles = {"tubelib_addons2_lamp.png^[colorize:#000000:100"},

	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons2:lamp")
		local meta = minetest.get_meta(pos)
		meta:set_int("number", number)
		switch_node(pos, "", placer)
		meta:set_string("formspec", "size[3,2]"..
		"label[0,0;Select color]"..
		"dropdown[0,0.5;3;type;"..sColor..";1]".. 
		"button_exit[0.5,1.5;2,1;exit;"..S("Save").."]")
		meta:set_int("color", 1)
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local meta = minetest.get_meta(pos)
		if fields.type then
			switch_node(pos, fields.type, player)
		end
		if fields.exit then
			meta:set_string("formspec", nil, player)
		end
	end,
	
	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)
		switch_node(pos, meta:get_int("color"), clicker)
	end,

	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,

	paramtype = 'light',
	sunlight_propagates = true,
	sounds = default.node_sound_stone_defaults(),
	groups = {choppy=2, cracky=1},
	is_ground_content = false,
})

tubelib.register_node("tubelib_addons2:lamp", {}, {
	on_recv_message = function(pos, topic, payload)
		if topic == "on" then
			local meta = minetest.get_meta(pos)
			switch_node(pos, meta:get_int("color") or "", nil)
		elseif topic == "off" then
			switch_node(pos, "", nil)
		end
	end,
})	


minetest.register_craft({
	output = "tubelib_addons2:lamp 2",
	recipe = {
		{"wool:green",       "wool:red",           "wool:blue"},
		{"tubelib:wlanchip", "default:coal_lump",  "tubelib:wlanchip"},
		{"group:wood",       "",                   "group:wood"},
	},
})

for idx,color in ipairs(tColors) do
	minetest.register_node("tubelib_addons2:lamp"..idx, {
		description = S("Tubelib Color Lamp"),
		tiles = {
			"tubelib_addons2_lamp.png^[colorize:"..color..":120",
		},

		on_receive_fields = function(pos, formname, fields, player)
			local meta = minetest.get_meta(pos)
			if fields.type then
				switch_node(pos, fields.type, player)
			end
			if fields.exit then
				meta:set_string("formspec", nil)
			end
		end,
		
		on_rightclick = function(pos, node, clicker)
			switch_node(pos, "", clicker)
		end,

		after_dig_node = function(pos)
			tubelib.remove_node(pos)
		end,

		paramtype = 'light',
		light_source = minetest.LIGHT_MAX,	
		sounds = default.node_sound_stone_defaults(),
		groups = {choppy=2, cracky=1, not_in_creative_inventory=1},
		is_ground_content = false,
		drop = "tubelib_addons2:lamp"
	})
end
