--[[

	Tubelib Addons 3
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	teleporter.lua
	
	A node, moving items to the peer teleporter node.

]]--

-- Load support for I18n
local S = tubelib_addons3.S
local M = minetest.get_meta

local Tube = tubelib.Tube

local sFormspec = "size[7.5,3]"..
	"field[0.5,1;7,1;channel;"..S("Enter channel string")..";]" ..
	"button_exit[2,2;3,1;exit;"..S("Save").."]"

minetest.register_node("tubelib_addons3:teleporter", {
	description = S("Tubelib Teleporter"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_addons3_chest_bottom.png',
		'tubelib_addons3_chest_bottom.png',
		'tubelib_addons3_chest_bottom.png^tubelib_hole.png',
		'tubelib_addons3_chest_bottom.png^tubelib_addons3_teleporter.png',
		'tubelib_addons3_chest_bottom.png^tubelib_addons3_teleporter.png',
		'tubelib_addons3_chest_bottom.png^tubelib_addons3_teleporter.png',
	},

	after_place_node = function(pos, placer)
		tubelib.add_node(pos, "tubelib_addons3:teleporter")
		-- determine the tube side
		local tube_dir = tubelib2.side_to_dir("R", minetest.dir_to_facedir(placer:get_look_dir()))
		Tube:prepare_pairing(pos, tube_dir, sFormspec)
		Tube:after_place_node(pos, {tube_dir})
	end,

	on_receive_fields = function(pos, formname, fields, player)
		if fields.channel ~= nil then
			Tube:pairing(pos, fields.channel)
		end
	end,
	
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Tube:stop_pairing(pos, oldmetadata, sFormspec)
		local tube_dir = tonumber(oldmetadata.fields.tube_dir or 0)
		Tube:after_dig_node(pos, {tube_dir})
	end,
	
	on_rotate = screwdriver.disallow,
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_craft({
	output = "tubelib_addons3:teleporter 2",
	recipe = {
		{"default:gold_ingot", "group:wood", ""},
		{"default:mese_crystal", "default:mese_crystal", "tubelib:tubeS"},
		{"default:gold_ingot", "group:wood", ""},
	},
})

Tube:add_secondary_node_names({"tubelib_addons3:teleporter"})
Tube:set_valid_sides("tubelib_addons3:teleporter", {"R"})
