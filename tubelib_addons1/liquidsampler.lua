--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	liquidsampler.lua
	
]]--

-- Load support for I18n
local S = tubelib_addons1.S

-- for lazy programmers
local P = minetest.string_to_pos
local M = minetest.get_meta

local STANDBY_TICKS = 4
local COUNTDOWN_TICKS = 2
local CYCLE_TIME = 8

local function formspec(self, pos, meta)
	return "size[9,8.5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;src;0,0;1,4;]"..
	"image[0,0;1,1;bucket.png]"..
	"image[1,1;1,1;tubelib_gui_arrow.png]"..
	"image_button[1,3;1,1;".. self:get_state_button_image(meta) ..";state_button;]"..
	"list[context;dst;2,0;7,4;]"..
	"list[current_player;main;0.5,4.5;8,4;]"..
	"listring[current_player;main]"..
	"listring[context;src]" ..
	"listring[current_player;main]"..
	"listring[context;dst]" ..
	"listring[current_player;main]"
end

local State = tubelib.NodeStates:new({
	node_name_passive = "tubelib_addons1:liquidsampler",
	node_name_active = "tubelib_addons1:liquidsampler_active",
	node_name_defect = "tubelib_addons1:liquidsampler_defect",
	infotext_name = S("Liquid Sampler"),
	cycle_time = CYCLE_TIME,
	standby_ticks = STANDBY_TICKS,
	has_item_meter = true,
	aging_factor = 8,
	formspec_func = formspec,
})

local function get_pos(pos, facedir, side)
	local offs = {F=0, R=1, B=2, L=3, D=4, U=5}
	local dst_pos = table.copy(pos)
	facedir = (facedir + offs[side]) % 4
	local dir = minetest.facedir_to_dir(facedir)
	return vector.add(dst_pos, dir)
end	


local function test_liquid(node)
	local liquiddef = bucket.liquids[node.name]
	if liquiddef ~= nil	and liquiddef.itemname ~= nil and 
			node.name == liquiddef.source then
		return liquiddef.itemname
	end
end

local function sample_liquid(pos, meta)
	local water_pos = P(meta:get_string("water_pos"))
	local giving_back = test_liquid(minetest.get_node(water_pos))
	if giving_back then
		local inv = meta:get_inventory()
		if inv:room_for_item("dst", ItemStack(giving_back)) and
				inv:contains_item("src", ItemStack("bucket:bucket_empty")) then
			minetest.remove_node(water_pos)
			inv:remove_item("src", ItemStack("bucket:bucket_empty"))
			inv:add_item("dst", ItemStack(giving_back))
			State:keep_running(pos, meta, COUNTDOWN_TICKS)
		else
			State:blocked(pos, meta)
		end
	else
		State:idle(pos, meta)
	end
	State:idle(pos, meta)
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	if listname == "src" and State:get_state(M(pos)) == tubelib.STANDBY then
		State:start(pos, M(pos))
	end
	return stack:get_count()
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local inv = M(pos):get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function keep_running(pos, elapsed)
	if tubelib.data_not_corrupted(pos) then
		local meta = M(pos)
		sample_liquid(pos, meta)
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

minetest.register_node("tubelib_addons1:liquidsampler", {
	description = S("Liquid Sampler"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_addons1_liquidsampler.png',
		'tubelib_addons1_liquidsampler_passive.png',
		'tubelib_addons1_liquidsampler.png',
		'tubelib_addons1_liquidsampler.png',
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons1:liquidsampler")
		State:node_init(pos, number)
		local meta = M(pos)
		local node = minetest.get_node(pos)
		local water_pos = get_pos(pos, node.param2, "L")
		meta:set_string("water_pos", minetest.pos_to_string(water_pos))
		local inv = meta:get_inventory()
		inv:set_size("src", 4)
		inv:set_size("dst", 28)
	end,

	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local inv = M(pos):get_inventory()
		return inv:is_empty("dst") and inv:is_empty("src")
	end,

	on_dig = function(pos, node, player)
		State:on_dig_node(pos, node, player)
		tubelib.remove_node(pos)
	end,
	
	on_rotate = screwdriver.disallow,
	on_timer = keep_running,
	on_receive_fields = on_receive_fields,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("tubelib_addons1:liquidsampler_active", {
	description = S("Liquid Sampler"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_addons1_liquidsampler.png',
		{
			image = "tubelib_addons1_liquidsampler_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 2,
			},
		},
		'tubelib_addons1_liquidsampler.png',
		'tubelib_addons1_liquidsampler.png',
	},

	diggable = false,
	can_dig = function() return false end,

	on_rotate = screwdriver.disallow,
	on_timer = keep_running,
	on_receive_fields = on_receive_fields,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("tubelib_addons1:liquidsampler_defect", {
	description = S("Liquid Sampler"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_addons1_liquidsampler.png^tubelib_defect.png',
		'tubelib_addons1_liquidsampler_passive.png^tubelib_defect.png',
		'tubelib_addons1_liquidsampler.png^tubelib_defect.png',
		'tubelib_addons1_liquidsampler.png^tubelib_defect.png',
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons1:liquidsampler")
		State:node_init(pos, number)
		local meta = M(pos)
		local node = minetest.get_node(pos)
		local water_pos = get_pos(pos, node.param2, "L")
		meta:set_string("water_pos", minetest.pos_to_string(water_pos))
		local inv = meta:get_inventory()
		inv:set_size("src", 4)
		inv:set_size("dst", 28)
		State:defect(pos, meta)
	end,

	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local inv = M(pos):get_inventory()
		return inv:is_empty("dst") and inv:is_empty("src")
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
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	output = "tubelib_addons1:liquidsampler",
	recipe = {
		{"group:wood", "default:steel_ingot", "group:wood"},
		{"default:mese_crystal", "bucket:bucket_empty", "tubelib:tubeS"},
		{"group:wood", "default:steel_ingot", "group:wood"},
	},
})

tubelib.register_node("tubelib_addons1:liquidsampler", 
	{"tubelib_addons1:liquidsampler_active", "tubelib_addons1:liquidsampler_defect"}, {
	invalid_sides = {"L"},
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
