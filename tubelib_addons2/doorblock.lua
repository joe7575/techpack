--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	doorblock.lua:
	
]]--

local sTextures = "Gate Wood,Aspen Wood,Jungle Wood,Pine Wood,"..
                  "Cobblestone,Sandstone,Stone,Desert Sandstone,"..
                  "Copper,Steel,Tin,Coral,"..
				  "Glas,Obsidian Glas"  

local tTextures = {
	["Gate Wood"]=1, ["Aspen Wood"]=2, ["Jungle Wood"]=3, ["Pine Wood"]=4,
	["Cobblestone"]=5, ["Sandstone"]=6, ["Stone"]=7, ["Desert Sandstone"]=8,
	["Copper"]=9, ["Steel"]=10, ["Tin"]=11, ["Coral"]=12,
	["Glas"]=13, ["Obsidian Glas"]=14,
}
	
local tPgns = {"tubelib_addon2_door.png", "default_aspen_wood.png", "default_junglewood.png", "default_pine_wood.png",
	"default_cobble.png", "default_sandstone.png", "default_stone.png", "default_desert_sandstone.png",
	"default_copper_block.png", "default_steel_block.png", "default_tin_block.png", "default_coral_skeleton.png",
	"default_glass.png", "default_obsidian_glass.png"}

local not_in_inventory=nil
for idx,pgn in ipairs(tPgns) do
	minetest.register_node("tubelib_addons2:doorblock"..idx, {
		description = "Tubelib Door Block",
		tiles = {
			pgn.."^[transformR90",
			pgn,
			pgn.."^[transformR90",
			pgn.."^[transformR90",
			pgn,
			pgn.."^[transformFX",
		},
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{ -8/16, -8/16, -2/16,  8/16,  8/16, 2/16},
			},
		},

		after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			local node = minetest.get_node(pos)
			local number = tubelib.add_node(pos, "tubelib_addons2:doorblock"..idx)
			tubelib.set_data(number, "facedir", node.param2)
			meta:set_string("number", number)
			meta:set_string("infotext", "Tubelib Door Block "..number)
			meta:set_string("formspec", "size[3,2]"..
			"label[0,0;Select texture]"..
			"dropdown[0,0.5;3;type;"..sTextures..";1]".. 
			"button_exit[0.5,1.5;2,1;exit;Save]")
		end,

		on_receive_fields = function(pos, formname, fields, player)
			local meta = minetest.get_meta(pos)
			local node = minetest.get_node(pos)
			local number = meta:get_string("number")
			if fields.type then
				node.name = "tubelib_addons2:doorblock"..tTextures[fields.type]
				minetest.swap_node(pos, node)
				tubelib.set_data(number, "texture", node.name)
			end
			if fields.exit then
				meta:set_string("formspec", nil)
			end
		end,
		
		after_dig_node = function(pos, oldnode, oldmetadata)
			tubelib.remove_node(pos)
		end,

		--drawtype = "glasslike",
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		sounds = default.node_sound_stone_defaults(),
		groups = {cracky=2, choppy=2, crumbly=2, not_in_creative_inventory=not_in_inventory},
		is_ground_content = false,
		drop = "tubelib_addons2:doorblock1",
	})

	not_in_inventory = 1
	
	tubelib.register_node("tubelib_addons2:doorblock"..idx, {}, {
		on_recv_message = function(pos, topic, payload)
			local node = minetest.get_node(pos)
			if topic == "on" then
				minetest.remove_node(pos)
			elseif topic == "off" then
				local num = tubelib.get_node_number(pos)
				local name = tubelib.get_data(num, "texture") or "tubelib_addons2:doorblock1"
				if name then
					minetest.add_node(pos, {name=name, 
							paramtype2="facedir", 
							param2=tubelib.get_data(num, "facedir")})
				end
			end
		end,
	})		
end

minetest.register_craft({
	output = "tubelib_addons2:doorblock1",
	recipe = {
		{"tubelib:wlanchip", "", ""},
		{"group:wood", "", ""},
		{"", "",""},
	},
})
