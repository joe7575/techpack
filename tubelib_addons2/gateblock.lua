--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	gateblock.lua:
	
]]--

local NUM_TEXTURES = 20

local sTextures = "Wood,Aspen Wood,Jungle Wood,Pine Wood,"..
                  "Cobblestone,Sandstone,Stone,Desert Sandstone,"..
				  "Desert Stone,Silver Sandstone,Mossy Cobble,Desert Cobble,"..  
                  "Copper,Steel,Tin,Coral,"..
				  "Glas,Obsidian Glas,Ice,Gate Wood"  

local tTextures = {
	["Wood"]=1, ["Aspen Wood"]=2, ["Jungle Wood"]=3, ["Pine Wood"]=4,
	["Cobblestone"]=5, ["Sandstone"]=6, ["Stone"]=7, ["Desert Sandstone"]=8,
	["Desert Stone"]=9, ["Silver Sandstone"]=10, ["Mossy Cobble"]=11, ["Desert Cobble"]=12,
	["Copper"]=13, ["Steel"]=14, ["Tin"]=15, ["Coral"]=16,
	["Glas"]=17, ["Obsidian Glas"]=18, ["Ice"]=19, ["Gate Wood"]=20,
}
	
local tPgns = {"default_wood.png", "default_aspen_wood.png", "default_junglewood.png", "default_pine_wood.png",
	"default_cobble.png", "default_sandstone.png", "default_stone.png", "default_desert_sandstone.png",
	"default_desert_stone_block.png", "default_silver_sandstone.png", "default_mossycobble.png", "default_desert_cobble.png",
	"default_copper_block.png", "default_steel_block.png", "default_tin_block.png", "default_coral_skeleton.png",
	"default_glass.png", "default_obsidian_glass.png", "default_ice.png", "tubelib_addon2_gate.png"}

for idx,pgn in ipairs(tPgns) do
	minetest.register_node("tubelib_addons2:gateblock"..idx, {
		description = "Tubelib Gate Block",
		tiles = {pgn},
		after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			local node = minetest.get_node(pos)
			local number = tubelib.add_node(pos, "tubelib_addons2:gateblock"..idx)
			meta:set_string("infotext", "Tubelib Gate Block "..number)
			meta:set_string("formspec", "size[3,2]"..
			"label[0,0;Select texture]"..
			"dropdown[0,0.5;3;type;"..sTextures..";"..NUM_TEXTURES.."]".. 
			"button_exit[0.5,1.5;2,1;exit;Save]")
		end,

		on_receive_fields = function(pos, formname, fields, player)
			local meta = minetest.get_meta(pos)
			local node = minetest.get_node(pos)
			if fields.type then
				node.name = "tubelib_addons2:gateblock"..tTextures[fields.type]
				minetest.swap_node(pos, node)
				tubelib.add_node(pos, node.name)
			end
			if fields.exit then
				meta:set_string("formspec", nil)
			end
		end,
		
		after_dig_node = function(pos)
			tubelib.remove_node(pos)
		end,

		drawtype = "glasslike",
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		sounds = default.node_sound_stone_defaults(),
		groups = {cracky=2, choppy=2, crumbly=2, not_in_creative_inventory = idx==NUM_TEXTURES and 0 or 1},
		is_ground_content = false,
		drop = "tubelib_addons2:gateblock1",
	})

	not_in_inventory = 1
	
	tubelib.register_node("tubelib_addons2:gateblock"..idx, {}, {
		on_recv_message = function(pos, topic, payload)
			local node = minetest.get_node(pos)
			if topic == "on" then
				minetest.remove_node(pos)
			elseif topic == "off" then
				local num = tubelib.get_node_number(pos)
				local info = tubelib.get_node_info(num)
				if info then
					minetest.add_node(pos, {name=info.name})
				end
			end
		end,
	})		
end

minetest.register_craft({
	output = "tubelib_addons2:gateblock"..NUM_TEXTURES,
	recipe = {
		{"group:wood",       "", ""},
		{"tubelib:wlanchip", "", ""},
		{"", "",""},
	},
})
