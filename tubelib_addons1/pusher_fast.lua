--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017-2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	pusher_fast.lua:
	
	Fast pusher for push/pull operation of StackItems from chests or other
	inventory/server nodes to tubes or other inventory/server nodes.
	
	The Pusher supports the following messages:
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

local RUNNING_STATE = 10 

local function switch_on(pos, node)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", RUNNING_STATE)
	meta:set_string("infotext", "Fast Pusher "..number..": running")
	node.name = "tubelib_addons1:pusher_fast_active"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):start(1)
	return false
end	

local function switch_off(pos, node)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", tubelib.STATE_STOPPED)
	meta:set_string("infotext", "Fast Pusher "..number..": stopped")
	node.name = "tubelib_addons1:pusher_fast"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):stop()
	return false
end	

local function goto_standby(pos, node)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", tubelib.STATE_STANDBY)
	meta:set_string("infotext", "Fast Pusher "..number..": standby")
	node.name = "tubelib_addons1:pusher_fast"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):start(20)
	return false
end	

local function goto_blocked(pos, node)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", tubelib.STATE_BLOCKED)
	meta:set_string("infotext", "Fast Pusher "..number..": blocked")
	node.name = "tubelib_addons1:pusher_fast"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):start(20)
	return false
end	

local function keep_running(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	local running = meta:get_int("running") - 1
	local player_name = meta:get_string("player_name")
	local items = tubelib.pull_items(pos, "L", player_name) -- <<=== tubelib
	if items ~= nil then
		if tubelib.push_items(pos, "R", items, player_name) == false then -- <<=== tubelib
			-- place item back
			tubelib.unpull_items(pos, "L", items, player_name) -- <<=== tubelib
			local node = minetest.get_node(pos)
			return goto_blocked(pos, node)
		end
		meta:set_int("item_counter", meta:get_int("item_counter") + 1)
		if running <= 0 then
			local node = minetest.get_node(pos)
			return switch_on(pos, node)
		else
			-- reload running state
			running = RUNNING_STATE
		end
	else
		if running <= 0 then
			local node = minetest.get_node(pos)
			return goto_standby(pos, node)
		end
	end
	meta:set_int("running", running)
	return true
end

minetest.register_node("tubelib_addons1:pusher_fast", {
	description = "Tubelib Fast Pusher",
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
		meta:set_string("number", number)
		meta:set_string("infotext", "Pusher "..number..": stopped")
		meta:set_int("item_counter", 0)
	end,

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_on(pos, node)
		end
	end,

	after_dig_node = function(pos)
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
	description = "Tubelib Fast Pusher",
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
			switch_off(pos, node)
		end
	end,
	
	on_timer = keep_running,
	on_rotate = screwdriver.disallow,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
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

--------------------------------------------------------------- tubelib
tubelib.register_node("tubelib_addons1:pusher_fast", {"tubelib_addons1:pusher_fast_active"}, {
	on_pull_item = nil,  		-- pusher has no inventory
	on_push_item = nil,			-- pusher has no inventory
	on_unpull_item = nil,		-- pusher has no inventory
	is_pusher = true,           -- is a pulling/pushing node
	
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "on" then
			return switch_on(pos, node)
		elseif topic == "off" then
			return switch_off(pos, node)
		elseif topic == "state" then
			if node.name == "ignore" then  -- unloaded pusher?
				return "blocked"
			end
			local meta = minetest.get_meta(pos)
			local running = meta:get_int("running") or tubelib.STATE_STOPPED
			return tubelib.statestring(running)
		elseif topic == "counter" then
			local meta = minetest.get_meta(pos)
			return meta:get_int("item_counter")
		elseif topic == "clear_counter" then
			local meta = minetest.get_meta(pos)
			return meta:set_int("item_counter", 0)
		else
			return "not supported"
		end
	end,
})	
--------------------------------------------------------------- tubelib
