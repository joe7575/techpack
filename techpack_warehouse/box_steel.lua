--[[

	TechPack Warehouse
	==================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	box_steel.lua

]]--

-- Load support for I18n
local S = techpack_warehouse.S

--- for lazy programmers
local P = minetest.string_to_pos
local M = minetest.get_meta
local wh = techpack_warehouse

local NODE_NAME = "techpack_warehouse:box_steel"
local DESCRIPTION = S("Warehouse Box Steel")
local INV_SIZE = 400
local BACKGROUND_IMG = "default_steel_block.png" 


local Box = wh.Box:new({
	node_name = NODE_NAME, 
	description = DESCRIPTION, 
	inv_size = INV_SIZE, 
	background_img = BACKGROUND_IMG,
}) 

minetest.register_node(NODE_NAME, {
	description = DESCRIPTION.." (8 x "..INV_SIZE.." items)",
	tiles = wh.tiles(BACKGROUND_IMG),
	
	after_place_node = function(pos, placer, itemstack)
		return wh.after_place_node(Box, pos, placer, itemstack)
	end,
	on_receive_fields = function(pos, formname, fields, player)
		wh.on_receive_fields(Box, pos, formname, fields, player)
	end,
	on_timer = function(pos,elapsed)
		return wh.on_timer(Box, pos,elapsed)
	end,
	can_dig = function(pos)
		return wh.can_dig(Box, pos)
	end,
	on_dig = function(pos, node, player)
		wh.on_dig_node(Box, pos, node, player)
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return wh.allow_metadata_inventory_put(Box, pos, listname, index, stack, player)
	end,
	on_metadata_inventory_put = wh.on_metadata_inventory_put,
	allow_metadata_inventory_take = wh.allow_metadata_inventory_take,
	allow_metadata_inventory_move = wh.allow_metadata_inventory_move,
	
	on_rotate = screwdriver.disallow,
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node(NODE_NAME.."_active", {
	description = DESCRIPTION.." (8 x "..INV_SIZE.." items)",
	tiles = wh.tiles_active(BACKGROUND_IMG),
	
	after_place_node = function(pos, placer, itemstack)
		return wh.after_place_node(Box, pos, placer, itemstack)
	end,
	on_receive_fields = function(pos, formname, fields, player)
		wh.on_receive_fields(Box, pos, formname, fields, player)
	end,
	on_timer = function(pos,elapsed)
		return wh.on_timer(Box, pos,elapsed)
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return wh.allow_metadata_inventory_put(Box, pos, listname, index, stack, player)
	end,
	on_metadata_inventory_put = wh.on_metadata_inventory_put,
	allow_metadata_inventory_take = wh.allow_metadata_inventory_take,
	allow_metadata_inventory_move = wh.allow_metadata_inventory_move,
  
	diggable = false,
	can_dig = function() return false end,
	
	on_rotate = screwdriver.disallow,
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node(NODE_NAME.."_defect", {
	description = DESCRIPTION.." (8 x "..INV_SIZE.." items)",
	tiles = wh.tiles_defect(BACKGROUND_IMG),
	
	after_place_node = function(pos, placer, itemstack)
		wh.after_place_node(Box, pos, placer, itemstack)
		Box.State:defect(pos, M(pos))
	end,
	can_dig = function(pos)
		return wh.can_dig(Box, pos)
	end,
	on_dig = function(pos, node, player)
		wh.on_dig_node(Box, pos, node, player)
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return wh.allow_metadata_inventory_put(Box, pos, listname, index, stack, player)
	end,
	on_metadata_inventory_put = wh.on_metadata_inventory_put,
	allow_metadata_inventory_take = wh.allow_metadata_inventory_take,
	allow_metadata_inventory_move = wh.allow_metadata_inventory_move,
	
	on_rotate = screwdriver.disallow,
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

tubelib.register_node(NODE_NAME, 
	{NODE_NAME.."_active", NODE_NAME.."_defect"}, {
	on_push_item = function(pos, side, item)
		local meta = M(pos)
		meta:set_string("push_dir", wh.Turn180[side])
		local num = wh.inv_add_item(Box, meta, item)
		if num > 0 then
			item:set_count(num)
			return tubelib.put_item(meta, "shift", item)
		end
		return true
	end,
	on_pull_stack = function(pos, side)
		return tubelib.get_stack(M(pos), "main")
	end,
	on_pull_item = function(pos, side)
		return tubelib.get_item(M(pos), "main")
	end,
	on_unpull_item = function(pos, side, item)
		local meta = M(pos)
		local num = wh.inv_add_item(Box, meta, item)
		if num > 0 then
			-- this should never happen, but better safe than sorry
			item:set_count(num)
			return tubelib.put_item(meta, "shift", item)
		end
		return true
	end,

	on_recv_message = function(pos, topic, payload)
		local resp = Box.State:on_receive_message(pos, topic, payload)
		if resp then
			return resp
		elseif topic == "num_items" then
			return wh.get_num_items(M(pos), payload)
		else
			return "unsupported"
		end
	end,
	on_node_load = function(pos)
		Box.State:on_node_load(pos)
	end,
	on_node_repair = function(pos)
		return Box.State:on_node_repair(pos)
	end,
})	

minetest.register_craft({
	output = NODE_NAME,
	recipe = {
		{"default:steel_ingot", "tubelib:pusher", "default:steel_ingot"},
		{"", "tubelib_addons1:chest", ""},
		{"", "", ""},
	}
})
