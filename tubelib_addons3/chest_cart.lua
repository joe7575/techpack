--[[

	Tubelib Addons 3
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	chest.lua
	
	A high performance chest

]]--

-- Load support for I18n
local S = tubelib_addons3.S

local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2P = minetest.string_to_pos
local M = minetest.get_meta

local function on_rightclick(pos, node, clicker)
	if clicker and clicker:is_player() then
		if M(pos):get_int("userID") == 0 then
			minecart.show_formspec(pos, clicker)
		end
	end
end

local function formspec()
	return "size[8,6]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;main;3,0;2,2;]"..
	"list[current_player;main;0,2.3;8,4;]"..
	"listring[context;main]"..
	"listring[current_player;main]"
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	local owner = M(pos):get_string("owner")
	if owner ~= "" and owner ~= player:get_player_name() then
		return 0
	end
	return stack:get_count()
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	local owner = M(pos):get_string("owner")
	if owner ~= "" and owner ~= player:get_player_name() then
		return 0
	end
	return stack:get_count()
end

minetest.register_node("tubelib_addons3:chest_cart", {
	description = S("TA Chest Cart"),
	tiles = {
		-- up, down, right, left, back, front		
			"tubelib_addons3_chest_cart_top.png",
			"tubelib_addons3_chest_cart_bottom.png",
			"tubelib_addons3_chest_cart_side.png",
			"tubelib_addons3_chest_cart_side.png",
			"tubelib_addons3_chest_cart_front.png",
			"tubelib_addons3_chest_cart_front.png",
		},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-7/16,  3/16, -7/16, 7/16, 8/16, 7/16},
			{-8/16, -8/16, -8/16, 8/16, 3/16, 8/16},
		},
	},
	paramtype2 = "facedir",
	paramtype = "light",
	use_texture_alpha = true,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 2, crumbly = 2, choppy = 2},
	node_placement_prediction = "",
	diggable = false,
	
	on_place = minecart.on_nodecart_place,
	on_punch = minecart.on_nodecart_punch,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	on_rightclick = on_rightclick,
	
	after_place_node = function(pos, placer)
		local inv = M(pos):get_inventory()
		inv:set_size('main', 4)
		if placer and placer:is_player() then
			minecart.show_formspec(pos, placer)
		else
			M(pos):set_string("formspec", formspec())
		end
	end,
	
	set_cargo = function(pos, data)
		local inv = M(pos):get_inventory()
		for idx, stack in ipairs(data) do
			inv:set_stack("main", idx, stack)
		end
	end,
	
	get_cargo = function(pos)
		local inv = M(pos):get_inventory()
		local data = {}
		for idx = 1, 4 do
			local stack = inv:get_stack("main", idx)
			data[idx] = {name = stack:get_name(), count = stack:get_count()}
		end
		return data
	end,

	has_cargo = function(pos)
		local inv = minetest.get_meta(pos):get_inventory()
		return not inv:is_empty("main")
	end
})

minecart.register_cart_entity("tubelib_addons3:chest_cart_entity", "tubelib_addons3:chest_cart", "chest", {
	initial_properties = {
		physical = false,
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		visual = "wielditem",
		textures = {"tubelib_addons3:chest_cart"},
		visual_size = {x=0.66, y=0.66, z=0.66},
		static_save = false,
	},
})

tubelib.register_node("tubelib_addons3:chest_cart", {}, {
	on_pull_stack = function(pos, side)
		local meta = minetest.get_meta(pos)
		return tubelib.get_stack(meta, "main")
	end,
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		return tubelib.get_item(meta, "main")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
	
	on_recv_message = function(pos, topic, payload)
		if topic == "state" then
			local meta = minetest.get_meta(pos)
			return tubelib.get_inv_state(meta, "main")
		else
			return "unsupported"
		end
	end,
})	

minetest.register_craft({
	output = "tubelib_addons3:chest_cart",
	recipe = {
			{"default:junglewood", "default:chest_locked", "default:junglewood"},
			{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		},
})
