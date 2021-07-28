--[[

	Dispenser
	================

	Copyright (C) 2021 Oversword

	AGPL v3
	See LICENSE.txt for more information

	init.lua:
	
	A dispenser, capable of interacting with entities and nodes using items
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
	infotext_name = S("Dispenser"),
	cycle_time = CYCLE_TIME,
	first_cycle_time = FIRST_CYCLE,
	standby_ticks = STANDBY_TICKS,
	aging_factor = 5,
	formspec_func = formspec,
})

-- Inventory access callbacks
local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	if index == 10 then
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
	if index == 10 then
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


-- This doesn't work yet, need a tubelib update to utilise top & bottom faces
--[[
local orientations = {
	[0] = { 4,  8},
	      {13, 17},
	      {10,  6},
	      {20, 15},
}

local function orient_dispenser(pos, placer)
	if not placer then
		return
	end
	local pitch = math.deg(placer:get_look_vertical())
	local node = minetest.get_node(pos)
	if pitch > 55 then
		node.param2 = orientations[node.param2][1]
	elseif pitch < -55 then
		node.param2 = orientations[node.param2][2]
	else
		return
	end
	minetest.swap_node(pos, node)
end
]]
local function after_place_node(pos, placer)
	-- orient_dispenser(pos, placer)
	local meta = M(pos)
	local number = tubelib.add_node(pos, "dispenser:dispenser")
	State:node_init(pos, number)
	meta:set_string("player_name", placer:get_player_name())

	local inv = meta:get_inventory()
	inv:set_size('main', 10)
end

-- Creating a fake player to perform actions for us
local player_overrides = {
	default = function (wield_stack, dispenser_data)
		return function (key)
			if key == "set_wielded_item" then
				return function (player, new_stack)
					dispenser_data.meta:get_inventory():set_stack("main", dispenser_data.index, new_stack)
				end
			end
			if key:sub(1,4) == "set_" then
				return function () end
			end
			if key == "get_wielded_item" then
				return function ()
					return wield_stack
				end
			end
			if key == "get_pos" then
				return function ()
					return dispenser_data.pos
				end
			end
			if key == "get_look_dir" then
				return function ()
					return dispenser_data.dir
				end
			end
			if key == "get_inventory" then
				return function ()
					return dispenser_data.meta:get_inventory()
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


-- What speed should items be shot out at?
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


-- How does the dispenser choose which item to dispense?
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


-- What happens when the result of an action cannot fit in the dispenser?
local overflow_behaviour = "spit"
function dispenser.set_overflow_behaviour(new_behaviour)
	if type(new_behaviour) ~= "string" then
		minetest.log("error",
			("[Tubelib Dispenser] Overflow behaviour must be a string, %s given.")
				:format(type(new_behaviour)))
		return
	end
	local new_behaviour_lower = string.lower(new_behaviour)
	if new_behaviour_lower == "spit" or new_behaviour_lower == "drop" then
		overflow_behaviour = "spit"
	elseif new_behaviour_lower == "blocked" or new_behaviour_lower == "block" then
		overflow_behaviour = "blocked"
	elseif new_behaviour_lower == "shoot" then
		overflow_behaviour = "shoot"
	else
		minetest.log("error",
			("[Tubelib Dispenser] Overflow behaviour '%s' does not exist.")
				:format(new_behaviour))
	end
end


local actions = {
	rightclick_entity = {
		player_required = true,
		entity_required = true,
		check = function (_, entity)
			return entity and entity.on_rightclick
		end,
		act = function (item_stack, dispenser_data, player, _, entity)
			if not player then return item_stack, "player not logged in" end
			entity:on_rightclick(player)
			return
		end
	},
	punch_entity = {
		player_required = true,
		entity_required = true,
		check = function (_, entity)
			return entity and entity.on_punch
		end,
		act = function (item_stack, dispenser_data, player, _, entity)
			if not player then return item_stack, "player not logged in" end
			entity:on_punch(player)--puncher, time_from_last_punch, tool_capabilities, dir
			return
		end
	},
	rightclick_node = {
		player_required = true,
		node_required = true,
		check = function (_, node)
			return node and minetest.registered_nodes[node.name].on_rightclick
		end,
		act = function (item_stack, dispenser_data, player, node)
			if not player then return item_stack, "player not logged in" end
			local result = minetest.registered_nodes[node.name].on_rightclick(dispenser_data.front, node, player, item_stack, {
				type="node",
				under=dispenser_data.front,
				above=vector.add(dispenser_data.front, {x=0,y=1,z=0})
			})--pos, node, clicker, itemstack, pointed_thing
			return result
		end
	},
	punch_node = {
		player_required = true,
		node_required = true,
		check = function (_, node)
			return node and node.name ~= "air" and minetest.registered_nodes[node.name].on_punch
		end,
		act = function (item_stack, dispenser_data, player, node)
			if not player then return item_stack, "player not logged in" end
			minetest.registered_nodes[node.name].on_punch(dispenser_data.front, node, player, {
				type="node",
				under=dispenser_data.front,
				above=vector.add(dispenser_data.front, {x=0,y=1,z=0})
			}) -- pos, node, puncher, pointed_thing
			return
		end
	},
	use = {
		player_required = true,
		check = function (item_stack)
			local item_name = item_stack:get_name()
			local def = minetest.registered_items[item_name]
			return def and def.on_use
		end,
		act = function (item_stack, dispenser_data, player)
			if not player then return item_stack, "player not logged in" end
			local item_name = item_stack:get_name()
			local result = minetest.registered_items[item_name].on_use(item_stack, player, {
				type="node",
				under=dispenser_data.front,
				above=vector.add(dispenser_data.front, {x=0,y=1,z=0})
			})
			return result
		end
	},
	place = {
		player_required = true,
		check = function (item_stack)
			local item_name = item_stack:get_name()
			local def = minetest.registered_items[item_name]
			return def and def.on_place
		end,
		act = function (item_stack, dispenser_data, player)
			if not player then return item_stack, "player not logged in" end
			local item_name = item_stack:get_name()
			local result = minetest.registered_items[item_name].on_place(item_stack, player, {
				type="node",
				under=dispenser_data.front,
				above=dispenser_data.front
			})
			return result
		end
	},
	shoot = {
		check = function (item_stack)
			local item_name = item_stack:get_name()
			return minetest.registered_items[item_name]
		end,
		act = function (item_stack, dispenser_data)
			-- Dispense a node and give it a velocity
			local entity = minetest.add_item(dispenser_data.front, item_stack:take_item())
			entity:set_velocity({
				x = dispenser_data.dir.x*shoot_speed,
				y = dispenser_data.dir.y*shoot_speed,
				z = dispenser_data.dir.z*shoot_speed
			})
			return item_stack
		end
	}
}

local cached_action_configs = {}

-- Construct an action function config
local function action_config(action_list)
	local action_ref = ""
	for _,action_name in ipairs(action_list) do
		action_ref = action_ref.."|"..action_name
	end
	if cached_action_configs[action_ref] then
		return cached_action_configs[action_ref]
	end

	local player_required = false
	local entity_required = false
	local node_required = false
	for _,action_name in ipairs(action_list) do
		if actions[action_name] then
			if actions[action_name].player_required then
				player_required = true
			end
			if actions[action_name].entity_required then
				entity_required = true
			end
			if actions[action_name].node_required then
				node_required = true
			end
		end
	end
	cached_action_configs[action_ref] = {
		player_required = player_required,
		entity_required = entity_required,
		node_required = node_required,
		action = function (item_stack, dispenser_data, player, node, entity)
			for _,action_name in ipairs(action_list) do
				local item_name = item_stack:get_name()
				local result, reason, failure = dispenser.actions["attempt_"..action_name](item_stack, dispenser_data, player, node, entity)
				if not failure then
					return result, reason
				end
			end
			return item_stack, "no action configured"
		end
	}
	return cached_action_configs[action_ref]
end

-- Parse a (list of) action function names into a function config
local function parse_config(name, config)
	if type(config) == "string" then
		config = {config}
	end
	if type(config) == "table" then
		local accepted_actions = {}
		for _,action_name in ipairs(config) do
			if actions[action_name] then
				table.insert(accepted_actions, action_name)
			else
				minetest.log("error",
						("[Tubelib Dispenser] %s is not a valid action for %s."):format(action_name, name))
			end
		end
		if #accepted_actions == 0 then
			minetest.log("error", 
					("[Tubelib Dispenser] %s has not been provided any actions, "..
						"you should unregister this item if you expect it to have no action."):format(name))
			return
		end
		config = action_config(accepted_actions)
	elseif type(config) == "function" then
		config = {
			player_required = true,
			entity_required = true,
			node_required = true,
			action = config
		}
	else
		minetest.log("error",
				("[Tubelib Dispenser] a dispense action must be the name of an action (string), "..
					"a list of names (table), or a custom function: %s given for %s."):format(type(config), name))
		return
	end

	return config
end


local dispense_configs = {}

-- Register an item as dispensable with a custom config
function dispenser.register_dispensable(item_name, config, overrides)
	if dispense_configs[item_name] then
		minetest.log("warn",
			("[Tubelib Dispenser] %s is already registered as dispensable, registering it again may change expected behaviour.")
				:format(item_name))
	end
	local parsed_config = parse_config(item_name, config)
	if not parsed_config then return end

	dispense_configs[item_name] = parsed_config
	if overrides then
		dispenser.register_player_overrides(item_name, overrides)
	end
end

-- Overrides for player methods by item
function dispenser.register_player_overrides(item_name, overrides)
	if player_overrides[item_name] then
		minetest.log("warn",
				("[Tubelib Dispenser] %s already has overrides registered for it, "..
					"registering others may change expected behaviour."):format(item_name))
	end
	if not dispense_configs[item_name] then
		minetest.log("warn",
				("[Tubelib Dispenser] %s is not registered as dispensable, it is pointless "..
					"to register overrides for an item which is not dispensable."):format(item_name))
	end
	if type(overrides) ~= "function" then
		minetest.log("error",
				("[Tubelib Dispenser] Registered overrides must be a function, %s given for %s."):format(type(overrides), item_name))
		return
	end
	player_overrides[item_name] = overrides
end

function dispenser.unregister_dispensable(item_name)
	dispense_configs[item_name] = nil
	player_overrides[item_name] = nil
end


-- The default action if none is registered for an item
local default_action
function dispenser.set_default_action(config)
	local parsed_config = parse_config("the default action", config)
	if not parsed_config then return end
	default_action = parsed_config
end
dispenser.set_default_action({ "rightclick_entity", "use", "place", "shoot" })


-- Public Utility Functions (if you want to make a custom action)
dispenser.actions = {}

function dispenser.actions.detect_entity(dispenser_data)
	local pointed_thing = minetest.raycast(dispenser_data.pos, dispenser_data.front):next()
	if pointed_thing.type == "object" then
		return pointed_thing.ref:get_luaentity()
	end
end

function dispenser.actions.fake_player(item_stack, dispenser_data)
	local player_name = dispenser_data.meta:get_string("player_name")
	local player = minetest.get_player_by_name(player_name)
	if not player then
		return
	end

	local item_name = item_stack:get_name()
	local overrides = player_overrides[item_name] or player_overrides.default
	return fake_player(player, overrides(item_stack, dispenser_data, player_overrides.default))
end

-- Generate a set of utility functions for each action
for action_name, action in pairs(actions) do
	dispenser.actions["can_"..action_name] = action.check
	dispenser.actions[action_name] = action.act

	dispenser.actions["attempt_"..action_name] = function (item_stack, dispenser_data, player, node, entity)
		local things = {}
		if action.node_required then
			if not node then return end
			table.insert(things, node)
		end
		if action.entity_required then
			if not entity then return end
			table.insert(things, entity)
		end
		local valid
		if table.unpack then
			valid = dispenser.actions["can_"..action_name](item_stack, table.unpack(things))
		else
			valid = dispenser.actions["can_"..action_name](item_stack, unpack(things))
		end
		if valid then
			return dispenser.actions[action_name](item_stack, dispenser_data, player, node, entity)
		end
		return nil, nil, true
	end
end


-- Insert an item into an invetory - avoiding the hidden 10th stack
local function insert_item(inv, item_stack)
	local listname = "main"
	if inv:room_for_item(listname, item_stack) then
		local list = inv:get_list(listname)
		local remaining = item_stack
		for index, stack in ipairs(list) do
			if index ~= 10 then
				remaining = stack:add_item(remaining)
				if remaining:is_empty() then
					break
				end
			end
		end
		if remaining:is_empty() then
			inv:set_list(listname, list)
			return true
		end
		return false
	end
	return false
end

-- If a reason was given for failure, respond to it
local function response_state(pos, meta, reason)
	if reason == "blocked" then
		State:blocked(pos, meta)
	elseif reason then
		State:fault(pos, meta)
	else
		State:keep_running(pos, meta, COUNTDOWN_TICKS, 1)
	end
end

local function overflow_shoot(inv, overflow_stack, dispenser_data)
	local result, reason, failure = dispenser.actions.attempt_shoot(overflow_stack, dispenser_data)
	if failure then
		State:fault(dispenser_data.pos, dispenser_data.meta)
		return
	end
	-- If a modified stack is returned, replace the original
	if result then
		inv:set_stack("main", 10, result)
	end
	return reason
end

-- Perform a dispensing action and handle the inventory
local function dispensing(pos, meta)

	-- Calculate which block is in front of the dispenser
	local param2 = minetest.get_node(pos).param2
	local dir = minetest.facedir_to_dir(
			tubelib2.side_to_dir("F", param2) - 1)
	local front = vector.add(pos, dir)
	
	local inv = meta:get_inventory()

	-- Check if there is an existin overflow
	-- this should only matter for "blocked" but account for all of them just in case
	local overflow_stack = inv:get_stack("main", 10)
	if not overflow_stack:is_empty() then
		if overflow_behaviour == "spit" then
			minetest.add_item(vector.add(pos, {x=0,y=-0.5,z=0}), overflow_stack)
			inv:set_stack("main", 10, nil)
		elseif overflow_behaviour == "shoot" then
			local shoot_reason = overflow_shoot(inv, overflow_stack, {
				front = front,
				dir = dir,
				pos = pos,
				meta = meta,
				index = 10
			})
			response_state(pos, meta, shoot_reason)
			return
		elseif overflow_behaviour == "blocked" then
			local inserted = insert_item(inv, overflow_stack)
			if not inserted then
				State:blocked(pos, meta)
			else
				inv:set_stack("main", 10, nil)
				State:keep_running(pos, meta, COUNTDOWN_TICKS, 1)
			end
			return
		end
	end

	-- Get all choices of item stacks in inventory
	local list = inv:get_list("main")
	local indexes = {}
	for i, stack in pairs(list) do
		if i ~= 10 and not stack:is_empty() then
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

	-- Get the config and the required data
	local stack = inv:get_stack("main", index)
	local item_name = stack:get_name()
	local config = dispense_configs[item_name] or default_action
	local dispenser_data = {
		front = front,
		dir = dir,
		pos = pos,
		meta = meta,
		index = index
	}
	local player, node, entity
	if config.player_required then
		player = dispenser.actions.fake_player(stack, dispenser_data)
	end
	if config.node_required then
		node = minetest.get_node_or_nil(front)
	end
	if config.entity_required then
		entity = dispenser.actions.detect_entity(dispenser_data)
	end

	-- Attempt to dispense the item
	local result, reason = config.action(stack, dispenser_data, player, node, entity)

	-- If a modified stack is returned, replace the original
	if result then
		inv:set_stack("main", index, result)
	end

	-- React to an item being in the hidden 10th slot
	overflow_stack = inv:get_stack("main", 10)
	if not overflow_stack:is_empty() then
		if overflow_behaviour == "spit" then
			minetest.add_item(vector.add(pos, {x=0,y=-0.5,z=0}), overflow_stack)
			inv:set_stack("main", 10, nil)
		elseif overflow_behaviour == "shoot" then
			local shoot_reason = overflow_shoot(inv, overflow_stack, {
				front = front,
				dir = dir,
				pos = pos,
				meta = meta,
				index = 10
			})
			if shoot_reason then
				response_state(pos, meta, shoot_reason)
				return
			end
		elseif overflow_behaviour == "blocked" then
			State:blocked(pos, meta)
			return
		end
	end

	response_state(pos, meta, reason)
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
	description = S("Dispenser"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'dispenser_side.png',
		'dispenser_side.png',
		'dispenser_side.png',
		'dispenser_front.png',
	},

	after_place_node = after_place_node,

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
	description = S("Dispenser"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'dispenser_side.png',
		'dispenser_side.png',
		'dispenser_side.png',
		'dispenser_front.png',
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
	description = S("Dispenser"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'dispenser_side.png^tubelib_defect.png',
		'dispenser_side.png^tubelib_defect.png',
		'dispenser_side.png^tubelib_defect.png',
		'dispenser_front.png',
	},

	after_place_node = function(pos, placer)
		after_place_node(pos, placer)
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


minetest.register_craft({
	output = "dispenser:dispenser",
	recipe = {
		{"group:wood", "group:wood",      "default:mese_crystal"},
		{"group:wood", "default:diamond", "default:mese_crystal"},
		{"group:wood", "group:wood",      "default:mese_crystal"},
	},
})

tubelib.register_node("dispenser:dispenser", 
	{"dispenser:dispenser_active", "dispenser:dispenser_defect"}, {
	invalid_sides = {"F"},
	on_push_item = function(pos, side, item_stack)
		local meta = M(pos)
		if meta == nil or meta.get_inventory == nil then
			return false
		end

		local inv = meta:get_inventory()
		return insert_item(inv, item_stack)
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
