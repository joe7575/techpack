--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	pusher_fast.lua:
	
	Fast pusher for push/pull operation of StackItems from chests or other
	inventory/server nodes to tubes or other inventory/server nodes.
	
	The Pusher is based on the class NodeStates and supports the following messages:
	 - topic = "on", payload  = nil
	 - topic = "off", payload  = nil
	 - topic = "state", payload  = nil, 
	   response is "running", "stopped", "standby", "blocked", or "not supported"

]]--

--                 +--------+
--                /        /|
--               +--------+ |
--     IN (L) -->|        |x--> OUT (R)
--               | PUSHER | +
--               |        |/
--               +--------+

-- Load support for I18n
local S = tubelib_addons1.S

-- for lazy programmers
local P = minetest.string_to_pos
local M = minetest.get_meta

local STANDBY_TICKS = 5
local COUNTDOWN_TICKS = 5
local CYCLE_TIME = 1
local FIRST_CYCLE = 0.5

local State = tubelib.NodeStates:new({
	node_name_passive = "tubelib_addons1:pusher_fast",
	node_name_active = "tubelib_addons1:pusher_fast_active",
	node_name_defect = "tubelib_addons1:pusher_fast_defect",
	infotext_name = S("Fast Pusher"),
	cycle_time = CYCLE_TIME,
	first_cycle_time = FIRST_CYCLE,
	standby_ticks = STANDBY_TICKS,
	has_item_meter = true,
	aging_factor = 30,
})

local function pushing(pos, meta)
	local player_name = meta:get_string("player_name")
	local items = tubelib.pull_items(pos, "L", player_name)
	if items ~= nil then
		if tubelib.push_items(pos, "R", items, player_name) == false then
			-- place item back
			tubelib.unpull_items(pos, "L", items, player_name)
			State:blocked(pos, meta)
			return
		end
		if State.get_state(pos, meta) ~= tubelib.STOPPED then
			State:keep_running(pos, meta, COUNTDOWN_TICKS)
		end
		return
	end
	State:idle(pos, meta)
end

local function keep_running(pos, elapsed)
	if tubelib.data_not_corrupted(pos) then
		local meta = M(pos)
		pushing(pos, meta)
		return State:is_active(meta)
	end
	return false
end	

minetest.register_node("tubelib_addons1:pusher_fast", {
	description = S("Fast Pusher"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_addons1_pusher.png',
		'tubelib_addons1_pusher.png',
		'tubelib_outp.png',
		'tubelib_inp.png',
		"tubelib_addons1_pusher.png^[transformR180]",
		"tubelib_addons1_pusher.png",
	},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("player_name", placer:get_player_name())
		local number = tubelib.add_node(pos, "tubelib_addons1:pusher_fast")
		State:node_init(pos, number)
	end,

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			State:start(pos, M(pos))
		end
	end,

	on_dig = function(pos, node, player)
		State:on_dig_node(pos, node, player)
		tubelib.remove_node(pos)
	end,
	
	on_timer = keep_running,
	on_rotate = screwdriver.disallow,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_node("tubelib_addons1:pusher_fast_active", {
	description = S("Fast Pusher"),
	tiles = {
		-- up, down, right, left, back, front
		{
			image = "tubelib_addons1_pusher_an.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 1.0,
			},
		},
		{
			image = "tubelib_addons1_pusher_an.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 1.0,
			},
		},
		'tubelib_outp.png',
		'tubelib_inp.png',
		{
			image = "tubelib_addons1_pusher_an.png^[transformR180]",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 1.0,
			},
		},
		{
			image = "tubelib_addons1_pusher_an.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 1.0,
			},
		},
	},

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			State:stop(pos, M(pos))
		end
	end,
	
	on_timer = keep_running,
	on_rotate = screwdriver.disallow,

	diggable = false,
	can_dig = function() return false end,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("tubelib_addons1:pusher_fast_defect", {
	description = S("Fast Pusher"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_addons1_pusher.png',
		'tubelib_addons1_pusher.png',
		'tubelib_outp.png^tubelib_defect.png',
		'tubelib_inp.png^tubelib_defect.png',
		"tubelib_addons1_pusher.png^[transformR180]^tubelib_defect.png",
		"tubelib_addons1_pusher.png^tubelib_defect.png",
	},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("player_name", placer:get_player_name())
		local number = tubelib.add_node(pos, "tubelib_addons1:pusher_fast")
		State:node_init(pos, number)
		State:defect(pos, meta)
	end,

	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,
	
	on_timer = keep_running,
	on_rotate = screwdriver.disallow,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_craft({
	output = "tubelib_addons1:pusher_fast",
	recipe = {
		{"", "tubelib:pusher", ""},
		{"", "tubelib:pusher", ""},
		{"", "tubelib:pusher", ""},
	},
})

tubelib.register_node("tubelib_addons1:pusher_fast", 
	{"tubelib_addons1:pusher_fast_active", "tubelib_addons1:pusher_fast_defect"}, {
	on_pull_item = nil,  		-- pusher has no inventory
	on_push_item = nil,			-- pusher has no inventory
	on_unpull_item = nil,		-- pusher has no inventory
	is_pusher = true,           -- is a pulling/pushing node
	valid_sides = {"R","L"},
	
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
