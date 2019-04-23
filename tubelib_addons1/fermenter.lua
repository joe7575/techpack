--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017-2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	fermenter.lua
	
	The Fermenter converts 3 leave items of any kind into one Bio Gas item,
	needed by the Reformer to produce Bio Fuel.

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

local STANDBY_TICKS = 4
local COUNTDOWN_TICKS = 4
local CYCLE_TIME = 2
local NUM_LEAVES = 3 -- to produce on bio gas

local function formspec(self, pos, meta)
	return "size[8,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;src;0,0;3,3;]"..
	"item_image[0,0;1,1;default:leaves]"..
	"image[3.5,1;1,1;tubelib_gui_arrow.png]"..
	"image_button[3.5,3;1,1;".. self:get_state_button_image(meta) ..";state_button;]"..
	"list[context;dst;5,0;3,3;]"..
	"item_image[5,0;1,1;tubelib_addons1:biogas]"..
	"list[current_player;main;0,4.3;8,4;]"..
	"listring[context;dst]"..
	"listring[current_player;main]"..
	"listring[context;src]"..
	"listring[current_player;main]"
end

local State = tubelib.NodeStates:new({
	node_name_passive = "tubelib_addons1:fermenter",
	node_name_defect = "tubelib_addons1:fermenter_defect",
	infotext_name = "Tubelib Fermenter",
	cycle_time = CYCLE_TIME,
	standby_ticks = STANDBY_TICKS,
	has_item_meter = true,
	aging_factor = 10,
	formspec_func = formspec,
})

local function is_leaves(name)
	return (tubelib_addons1.FarmingNodes[name] ~= nil  and
	       tubelib_addons1.FarmingNodes[name].leaves == true) or
		minetest.get_item_group(name, "leaves") > 0
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = M(pos)
	local inv = meta:get_inventory()
	if listname == "src" and is_leaves(stack:get_name()) then
		if State:get_state(meta) == tubelib.STANDBY then
			State:start(pos, meta)
		end
		return stack:get_count()
	elseif listname == "dst" then
		return stack:get_count()
	end
	return 0
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = M(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end


local function place_top(pos, facedir, placer)
	if minetest.is_protected(pos, placer:get_player_name()) then
		return false
	end
	local node = minetest.get_node(pos)
	if node.name ~= "air" then
		return false
	end
	minetest.add_node(pos, {name="tubelib_addons1:fermenter_top", param2=facedir})
	return true
end

local function convert_leaves_to_biogas(pos, meta)
	local inv = meta:get_inventory()
	local biogas = ItemStack("tubelib_addons1:biogas")
	
	-- Not enough output space?
	if not inv:room_for_item("dst", biogas) then
		State:blocked(pos, meta)
		return
	end
	
	-- take NUM_LEAVES items
	local items = {}
	for i = 1, NUM_LEAVES do
		items[i] = tubelib.get_num_items(meta, "src", 1)
		if items[i] then  -- input available?
			if not is_leaves(items[i]:get_name()) then
				for j = 1, #items do
					inv:add_item("src", items[j])
				end
				State:fault(pos, meta)
				return
			end
		end
	end
		
	-- put result into dst inventory
	if #items == NUM_LEAVES then
		inv:add_item("dst", biogas)
		State:keep_running(pos, meta, COUNTDOWN_TICKS)
		return
	end
	
	-- put leaves back to src inventory
	for i = 1, #items do
		inv:add_item("src", items[i])
	end
	State:idle(pos, meta)
end

local function keep_running(pos, elapsed)
	if tubelib.data_not_corrupted(pos) then
		local meta = M(pos)
		convert_leaves_to_biogas(pos, meta)
		return State:is_active(meta)
	end
	return false
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	State:state_button_event(pos, fields)
end

minetest.register_node("tubelib_addons1:fermenter", {
	description = "Tubelib Fermenter",
	inventory_image = "tubelib_addons1_fermenter_inventory.png",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_addons1_fermenter_bottom.png',
		'tubelib_addons1_fermenter_bottom.png',
		'tubelib_addons1_fermenter_bottom.png',
		'tubelib_addons1_fermenter_bottom.png',
	},

	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, -8/16,   8/16, 24/16, 8/16 },
	},
	
	on_construct = function(pos)
		local meta = M(pos)
		local inv = meta:get_inventory()
		inv:set_size('src', 9)
		inv:set_size('dst', 9)
	end,
	
	after_place_node = function(pos, placer)
		local facedir = minetest.dir_to_facedir(placer:get_look_dir(), false)
		if place_top({x=pos.x, y=pos.y+1, z=pos.z}, facedir, placer) == false then
			minetest.remove_node(pos)
			return
		end
		local number = tubelib.add_node(pos, "tubelib_addons1:fermenter")
		State:node_init(pos, number)
	end,

	-- the fermenter needs 'on_dig' to be able to remove the upper node
	on_dig = function(pos, node, puncher, pointed_thing)
		local meta = M(pos)
		local inv = meta:get_inventory()
		if inv:is_empty("dst") and inv:is_empty("src") then
			minetest.node_dig(pos, node, puncher, pointed_thing)
			minetest.remove_node({x=pos.x, y=pos.y+1, z=pos.z})
		end
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		tubelib.remove_node(pos)
		State:after_dig_node(pos, oldnode, oldmetadata, digger)
	end,
	
	on_rotate = screwdriver.disallow,
	on_timer = keep_running,
	on_receive_fields = on_receive_fields,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	drop = "",
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("tubelib_addons1:fermenter_defect", {
	description = "Tubelib Fermenter defect",
	inventory_image = "tubelib_addons1_fermenter_inventory.png",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_addons1_fermenter_bottom.png^tubelib_defect.png',
		'tubelib_addons1_fermenter_bottom.png^tubelib_defect.png',
		'tubelib_addons1_fermenter_bottom.png^tubelib_defect.png',
		'tubelib_addons1_fermenter_bottom.png^tubelib_defect.png',
	},

	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, -8/16,   8/16, 24/16, 8/16 },
	},
	
	on_construct = function(pos)
		local meta = M(pos)
		local inv = meta:get_inventory()
		inv:set_size('src', 9)
		inv:set_size('dst', 9)
	end,
	
	after_place_node = function(pos, placer)
		local facedir = minetest.dir_to_facedir(placer:get_look_dir(), false)
		if place_top({x=pos.x, y=pos.y+1, z=pos.z}, facedir, placer) == false then
			minetest.remove_node(pos)
			return
		end
		local number = tubelib.add_node(pos, "tubelib_addons1:fermenter")
		State:node_init(pos, number)
		State:defect(pos, M(pos))
	end,

	-- the fermenter needs 'on_dig' to be able to remove the upper node
	on_dig = function(pos, node, puncher, pointed_thing)
		local meta = M(pos)
		local inv = meta:get_inventory()
		if inv:is_empty("dst") and inv:is_empty("src") then
			minetest.node_dig(pos, node, puncher, pointed_thing)
			minetest.remove_node({x=pos.x, y=pos.y+1, z=pos.z})
		end
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		tubelib.remove_node(pos)
	end,
	
	on_rotate = screwdriver.disallow,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("tubelib_addons1:fermenter_top", {
	description = "Tubelib Fermenter Top",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		"tubelib_front.png",
		'tubelib_addons1_fermenter_top.png',
		'tubelib_addons1_fermenter_top.png',
		'tubelib_addons1_fermenter_top.png',
		'tubelib_addons1_fermenter_top.png',
	},

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	pointable = false,
})

minetest.register_craftitem("tubelib_addons1:biogas", {
	description = "Bio Gas",
	inventory_image = "tubelib_addons1_biogas.png",
})

if minetest.global_exists("unified_inventory") then
	unified_inventory.register_craft_type("fermenting", {
		description = "Fermenter",
		icon = "tubelib_addons1_fermenter_inventory.png",
		width = 2,
		height = 2,
	})
	unified_inventory.register_craft_type("reforming", {
		description = "Reformer",
		icon = "tubelib_addons1_reformer_inventory.png",
		width = 2,
		height = 2,
	})
	unified_inventory.register_craft({
		items = {"group:leaves", "group:leaves"}, 
		output = "tubelib_addons1:biogas", 
		type = "fermenting"
	})
	unified_inventory.register_craft({
		items = {"tubelib_addons1:biogas", "tubelib_addons1:biogas", 
				"tubelib_addons1:biogas", "tubelib_addons1:biogas"}, 
		output = "tubelib_addons1:biofuel", 
		type = "reforming"
	})
end

minetest.register_craft({
	output = "tubelib_addons1:fermenter",
	recipe = {
		{"default:steel_ingot", "default:dirt", "default:steel_ingot"},
		{"tubelib:tubeS", "default:mese_crystal", "tubelib:tubeS"},
		{"default:steel_ingot", "group:wood", "default:steel_ingot"},
	},
})


tubelib.register_node("tubelib_addons1:fermenter", {"tubelib_addons1:fermenter_defect"}, {
	on_pull_item = function(pos, side)
		return tubelib.get_item(M(pos), "dst")
	end,
	on_push_item = function(pos, side, item)
		return tubelib.put_item(M(pos), "src", item)
	end,
	on_unpull_item = function(pos, side, item)
		return tubelib.put_item(M(pos), "dst", item)
	end,
	on_recv_message = function(pos, topic, payload)
		local resp = State:on_receive_message(pos, topic, payload)
		if resp then
			return resp
		else
			return "unsupported"
		end
	end,
	on_node_load = function(pos)
		State:on_node_load(pos)
	end,
	on_node_repair = function(pos)
		return State:on_node_repair(pos)
	end,
})	
