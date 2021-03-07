--[[

	Tubelib Addons 3
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	pushing_detector.lua
	
	A pusher that activates when an item is detected

]]--


-- Load support for I18n
local S = tubelib_addons3.S

-- for lazy programmers
local P = minetest.string_to_pos
local M = minetest.get_meta

local STANDBY_TICKS = 5
local CYCLE_TIME = 2

local State = tubelib.NodeStates:new({
	node_name_passive = "tubelib_addons3:pushing_detector",
	node_name_active = "tubelib_addons3:pushing_detector_active",
	node_name_defect = "tubelib_addons3:pushing_detector_defect",
	infotext_name = S("Pushing Detector"),
	cycle_time = CYCLE_TIME,
	standby_ticks = STANDBY_TICKS,
	has_item_meter = true,
	aging_factor = 50,
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
		return
	end
end

local function switch_on(pos)
	if tubelib.data_not_corrupted(pos) then
		local node = minetest.get_node(pos)
		node.name = "tubelib_addons3:pushing_detector_active"
		minetest.swap_node(pos, node)
		local meta = M(pos)
		State:start(pos, meta)
		minetest.get_node_timer(pos):start(1)
		pushing(pos, meta)
	end
end


local function switch_off(pos)
	if tubelib.data_not_corrupted(pos) then
		local meta = M(pos)
		local node = minetest.get_node(pos)
		node.name = "tubelib_addons3:pushing_detector"
		minetest.swap_node(pos, node)
		State:standby(pos, meta)
	end
end

minetest.register_node("tubelib_addons3:pushing_detector", {
	description = S("Pushing Detector"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_pusher1.png',
		'tubelib_pusher1.png',
		'tubelib_outp.png',
		'tubelib_inp.png',
		'tubelib_front.png^tubelib_hole.png',
		'tubelib_front.png^tubelib_hole.png',
	},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("player_name", placer:get_player_name())
		local number = tubelib.add_node(pos, "tubelib_addons3:pushing_detector")
		State:node_init(pos, number)
	end,

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			local meta = M(pos)
			if State.get_state(pos, meta) == tubelib.STOPPED then
				State:start(pos, meta) -- will not enter standby state unless running
				State:standby(pos, meta)
			else
				State:stop(pos, meta)
			end
		end
	end,

	on_dig = function(pos, node, player)
		State:on_dig_node(pos, node, player)
		tubelib.remove_node(pos)
	end,
	
	on_timer = switch_off,
	on_rotate = screwdriver.disallow,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_node("tubelib_addons3:pushing_detector_active", {
	description = S("Pushing Detector"),
	tiles = {
		-- up, down, right, left, back, front
		{
			image = "tubelib_pusher.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 2.0,
			},
		},
		{
			image = "tubelib_pusher.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 2.0,
			},
		},
		'tubelib_outp.png',
		'tubelib_inp.png',
		'tubelib_front.png^tubelib_hole.png',
		'tubelib_front.png^tubelib_hole.png',
	},

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			State:stop(pos, M(pos))
		end
	end,
	
	on_timer = switch_off,
	on_rotate = screwdriver.disallow,

	diggable = false,
	can_dig = function() return false end,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	drop = "tubelib_addons3:pushing_detector",
})

minetest.register_node("tubelib_addons3:pushing_detector_defect", {
	description = S("Pushing Detector"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_pusher1.png',
		'tubelib_pusher1.png',
		'tubelib_outp.png^tubelib_defect.png',
		'tubelib_inp.png^tubelib_defect.png',
		'tubelib_front.png^tubelib_defect.png^tubelib_hole.png',
		'tubelib_front.png^tubelib_defect.png^tubelib_hole.png',
	},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("player_name", placer:get_player_name())
		local number = tubelib.add_node(pos, "tubelib_addons3:pushing_detector")
		State:node_init(pos, number)
		State:defect(pos, meta)
	end,

	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,
	
	on_timer = switch_off,
	on_rotate = screwdriver.disallow,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_craft({
	output = "tubelib_addons3:pushing_detector",
	recipe = {
		{"tubelib:pusher", "tubelib_addons1:detector", ""},
		{"", "", ""},
		{"", "", ""},
	},
})

tubelib.register_node("tubelib_addons3:pushing_detector", 
	{"tubelib_addons3:pushing_detector_active", "tubelib_addons3:pushing_detector_defect"}, {
	is_pusher = true,           -- is a pulling/pushing node
	valid_sides = {"R","L","F","B"},

	on_push_item = function(pos, side, item)
		if side ~= "F" and side ~= "B" then return false end
		local other_side = ({F="B",B="F"})[side]
		local player_name = minetest.get_meta(pos):get_string("player_name")
		if State.get_state(pos, M(pos)) == tubelib.STOPPED then
			return false
		end
		if tubelib.push_items(pos, other_side, item, player_name) then
			switch_on(pos)
			return true
		end
		return false
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
