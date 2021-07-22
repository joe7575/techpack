--[[

	Tubelib Addons 3
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	dispenser.lua:
	
	A high performance dispenser
]]--

dispenser = {}

-- Load support for I18n
local S = minetest.get_translator("dispenser")

-- for lazy programmers
local P = minetest.string_to_pos
local M = minetest.get_meta

local COUNTDOWN_TICKS = 8
local STANDBY_TICKS = 4
local CYCLE_TIME = 2
local FIRST_CYCLE = 0.5

local function formspec(self, pos, meta)
	return "size[9,7]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[context;main;2.5,0;3,3;]"..
		"image_button[5.5,1;1,1;"..self:get_state_button_image(meta)..";state_button;]"..
		"list[current_player;main;0.5,3.3;8,4;]"..
		"listring[context;main]"..
		"listring[current_player;main]"
end

local State = tubelib.NodeStates:new({
	node_name_passive = "dispenser:dispenser",
	node_name_active = "dispenser:dispenser_active",
	node_name_defect = "dispenser:dispenser_defect",
	infotext_name = S("HighPerf Dispenser"),
	cycle_time = CYCLE_TIME,
	first_cycle_time = FIRST_CYCLE,
	standby_ticks = STANDBY_TICKS,
	aging_factor = 50,
	formspec_func = formspec,
})

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = M(pos)
	if State:get_state(meta) == tubelib.STANDBY then
		State:start(pos, meta)
	end
	return stack:get_count()
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = M(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local PLACEABLE = "placeable"
local SHOOTABLE = "shootable"
local USABLE = "usable"
local default_action = "fault"
local dispense_configs = {}

local player_overrides = {
	default = function (item, front, dir, pos, meta)
		return function (key)
			if key:sub(1,4) == "set_" then
				return function () end
			end
			if key == "get_wielded_item" then
				return function ()
					return item
				end
			end
			if key == "get_pos" then
				return function ()
					return pos
				end
			end
			if key == "get_look_dir" then
				return function ()
					return dir
				end
			end
			if key == "get_inventory" then
				return function ()
					return meta:get_inventory()
				end
			end
		end
	end
}

local function fake_player(player, overrides)
	local fake = {}
	setmetatable(fake, {
		__index = function(mytable, key)
			local override = overrides(key)
			if override then
				return override
			end
			-- Default behaviour for everything else
			local v = player[key]
			if type(v) == "function" then
				return function (...)
					return player[key](player, ...)
				end
			end
			return v
		end
	})

	return fake
end

local shoot_speed = 10
function dispenser.set_shooting_speed(speed)
	if type(speed) ~= "number" then
		minetest.log("error",
			("[Tubelib Dispenser] Shooting speed must be a number, %s given.")
				:format(type(speed)))
		return
	end
	shoot_speed = speed
end

local function register_dispensable(name, mode)
	if dispense_configs[name] and dispense_configs[name] ~= mode then
		minetest.log("warn",
			("[Tubelib Dispenser] %s is already registered as %s, registering it as %s may change expected behaviour.")
				:format(name, dispense_configs[name], mode))
	end
	dispense_configs[name] = mode
end

function dispenser.register_placeable(name)
	register_dispensable(name, PLACEABLE)
end

function dispenser.register_shootable(name)
	register_dispensable(name, SHOOTABLE)
end

function dispenser.register_usable(name, player_override)
	register_dispensable(name, USABLE)
	if player_override then
		player_overrides[name] = player_override
	end
end

function dispenser.unregister(name)
	dispense_configs[name] = nil
end

function dispenser.set_default_action(action)
	if action == "use" or action == USABLE then
		default_action = USABLE
	elseif action == "shoot" or action == SHOOTABLE then
		default_action = SHOOTABLE
	elseif action == "place" or action == PLACEABLE then
		default_action = PLACEABLE
	elseif action == "fault" or action == "error" then
		default_action = "fault"
	else
		minetest.log("error",
			("[Tubelib Dispenser] '%s' is not a valid default action.")
				:format(action))
	end
end

local choice_strategy = "first"
local choice_strategies = {
	first = function(indexes)
		return indexes[1]
	end,
	random = function(indexes)
		return indexes[math.random(#indexes)]
	end
}

function dispenser.register_choice_strategy(name, strategy, use)
	if type(strategy) ~= "function" then
		minetest.log("error",
			("[Tubelib Dispenser] Index strategy '%s' must be a function, %s given.")
				:format(name, type(strategy)))
		return
	end
	choice_strategies[name] = strategy
	if use then
		choice_strategy = name
	end
end

function dispenser.set_choice_strategy(name)
	if not choice_strategies[name] then
		minetest.log("error",
			("[Tubelib Dispenser] Index strategy '%s' does not exist.")
				:format(name))
		return
	end
	choice_strategy = name
end

local function item_callback(callback, name, item, front, dir, pos, meta)
	-- We need a player for this to work
	local player_name = meta:get_string("player_name")
	local player = minetest.get_player_by_name(player_name)
	if not player then
		return item, "player not logged in"
	end

	local overrides = player_overrides[name] or player_overrides.default
	local clicker = fake_player(player, overrides(item, front, dir, pos, meta, player_overrides.default))

	-- Interacting with entities does not work because the callbacks insist the player is real and not faked
	-- local pointed_thing = minetest.raycast(pos, front):next()
	-- if pointed_thing.type == "object" then
	-- 	minetest.log("error", dump(pointed_thing.ref:right_click(clicker)))
	-- end

	-- Trigger the on_use callback with a fake player and pointed_thing object
	local result = callback(
		item,
		clicker,
		-- pointed_thing)
		{
			type="node",
			under=front,
			above=vector.add(front, {x=0,y=1,z=0})
		})

	-- This happens if the on_use callback is exited unsuccessfully
	if not result then
		return item
	end

	-- This happens if the on_use callback removes items from the  stack and returns it
	if result:is_empty() then
		return
	end

	-- This happens if the item was modified or a new item was returned from the on_use callback
	return result
end

-- actually dispense an item, return an item if it goes unused, or remains but is modified
local function dispense(item, front, dir, pos, meta)
	local name = item:get_name()
	local action = dispense_configs[name] or default_action

	if action == PLACEABLE then
		-- Check if we can actually place an item there
		local front_node = minetest.get_node_or_nil(front)
		local front_def = front_node and minetest.registered_nodes[front_node.name]
		if not front_def or not front_def.buildable_to then
			return item, "blocked"
		end

		-- Use on_place callback if it exists
		local placed_item_def = minetest.registered_items[name]
		if placed_item_def.on_place then
			return item_callback(placed_item_def.on_place, name, item, front, dir, pos, meta)
		end

		-- Make sure the item has a node and is not just an item
		local placed_node_def = minetest.registered_nodes[name]
		if not placed_node_def then
			return item, "cannot be placed"
		end

		-- Place the node and trigger an update
		minetest.set_node(front, {name=name})
		minetest.check_for_falling(front)
		return
	elseif action == USABLE then
		-- Check if item actually exists and can be used
		local def = minetest.registered_items[name]
		if not def or not def.on_use then
			return item, "cannot be used"
		end
		return item_callback(def.on_use, name, item, front, dir, pos, meta)
	elseif action == SHOOTABLE then
		-- Dispense a node and give it a velocity
		local entity = minetest.add_item(front, item)
		entity:set_velocity({
			x = dir.x*shoot_speed,
			y = dir.y*shoot_speed,
			z = dir.z*shoot_speed
		})
		return
	end

	return item, "no action configured"
end

-- perform a dispensing action and handle the inventory
local function dispensing(pos, meta)
	
	local inv = meta:get_inventory()
	local list = inv:get_list("main")

	-- Get all choices of item stacks in inventory
	local indexes = {}
	for i, stack in pairs(list) do
		if not stack:is_empty() then
			table.insert(indexes, i)
		end
	end

	-- If there is nothing to do, set standby state and exit
	if #indexes == 0 then
		State:idle(pos, meta)
		return
	end

	-- Pick which stack to use based on the choice strategy
	local index = choice_strategies[choice_strategy](indexes)

	-- Remove the item to be used
	local stack = inv:get_stack("main", index)
	local item = stack:take_item()
	inv:set_stack("main", index, stack)

	-- Calculate which block is in front of the dispenser
	local param2 = minetest.get_node(pos).param2
	local dir = minetest.facedir_to_dir(
			tubelib2.side_to_dir("R", param2) - 1)
	local front = vector.add(pos, dir)

	-- Attempt to dispense the item
	local result, reason = dispense(item, front, dir, pos, meta)

	-- If the dispense() returned an item, try to put it back in the inventory, or spit it out
	if result then
		if inv:room_for_item("main", result) then
			-- Try to put back in original stack
			local leftover = stack:add_item("main", result)
			if leftover:is_empty() then
				inv:set_stack("main", index, stack)
			else -- If it won't fit in the original stack, put it anywhere
				inv:add_item("main", result)
			end
		else
			-- Spit out item if full
			minetest.add_item(pos, result)
		end
	end

	-- If a reason was given for failure, we should respond to it
	if reason == "blocked" then
		State:blocked(pos, meta)
	elseif reason then
		minetest.log("error", reason)
		State:fault(pos, meta)
	else
		State:keep_running(pos, meta, COUNTDOWN_TICKS, 1)
	end
end

local function keep_running(pos, elapsed)
	if tubelib.data_not_corrupted(pos) then
		local meta = M(pos)
		dispensing(pos, meta)
		return State:is_active(meta)
	end
	return false
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local meta = M(pos)
	
	if fields.state_button ~= nil then
		State:state_button_event(pos, fields)
	else
		meta:set_string("formspec", formspec(State, pos, meta))
	end
end

minetest.register_node("dispenser:dispenser", {
	description = S("HighPerf Dispenser"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png^tubelib_addons3_node_frame.png',
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png',
	},

	after_place_node = function(pos, placer)
		local meta = M(pos)
		local number = tubelib.add_node(pos, "dispenser:dispenser")
		State:node_init(pos, number)
		meta:set_string("player_name", placer:get_player_name())

		local inv = meta:get_inventory()
		inv:set_size('main', 9)
	end,

	on_receive_fields = on_receive_fields,

	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local inv = M(pos):get_inventory()
		return inv:is_empty("main")
	end,
	
	on_dig = function(pos, node, player)
		State:on_dig_node(pos, node, player)
		tubelib.remove_node(pos)
	end,
	
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,

	on_timer = keep_running,
	on_rotate = screwdriver.disallow,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_node("dispenser:dispenser_active", {
	description = S("HighPerf Dispenser"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png^tubelib_addons3_node_frame.png',
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png',
	},

	on_receive_fields = on_receive_fields,
	
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,

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

minetest.register_node("dispenser:dispenser_defect", {
	description = S("HighPerf Dispenser"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png^tubelib_addons3_node_frame.png',
		'tubelib_front.png^tubelib_defect.png',
		'tubelib_front.png^tubelib_defect.png',
		'tubelib_front.png^tubelib_defect.png',
	},

	after_place_node = function(pos, placer)
		local meta = M(pos)
		local number = tubelib.add_node(pos, "dispenser:dispenser")
		State:node_init(pos, number)
		meta:set_string("player_name", placer:get_player_name())

		local inv = meta:get_inventory()
		inv:set_size('main', 9)
		State:defect(pos, meta)
	end,

	on_receive_fields = on_receive_fields,

	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local inv = M(pos):get_inventory()
		return inv:is_empty("main")
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		tubelib.remove_node(pos)
	end,
	
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,

	on_rotate = screwdriver.disallow,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


-- minetest.register_craft({
-- 	output = "dispenser:dispenser",
-- 	recipe = {
-- 		{"default:tin_ingot", "tubelib:dispenser", ""},
-- 		{"tubelib:dispenser", "default:gold_ingot", ""},
-- 		{"", "", ""},
-- 	},
-- })


tubelib.register_node("dispenser:dispenser", 
	{"dispenser:dispenser_active", "dispenser:dispenser_defect"}, {
	on_push_item = function(pos, side, item)
		return tubelib.put_item(M(pos), "main", item)
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




dispenser.register_usable("mobs:hairball", function (item, front, dir, pos, meta, default)
	return function (key)
		if key == "get_pos" then
			return function ()
				return vector.add(pos, {x=0,y=-1.5,z=0})
			end
		end
		return default(item, front, dir, pos, meta)(key)
	end
end)
dispenser.register_usable("bonemeal:bonemeal")
dispenser.register_usable("moreores:hoe_silver")
dispenser.register_usable("farming:hoe_wood")
dispenser.register_placeable("default:desert_sand")
dispenser.register_shootable("cucina_vegana:sunflower_seed")


dispenser.register_usable("bucket:bucket_empty")
dispenser.register_placeable("bucket:bucket_water")