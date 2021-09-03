--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017-2021 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	harvester.lua
	
	Harvester machine to chop wood, leaves and harvest farming crops and flowers.
	
	The machine is able to harvest an square area of up to 33x33 blocks (radius = 16).
	The base node has to be placed in the middle of the harvesting area.
	The Harvester processes one node every 6 seconds.
	It requires one item Bio Fuel per 20 nodes.

]]--

-- Load support for I18n
local S = tubelib_addons1.S

-- for lazy programmers
local P = minetest.string_to_pos
local M = minetest.get_meta

local CYCLE_TIME = 6
local START_HEIGHT = 18  -- harvesting altitude
local MAX_DIAMETER = 33
local BURNING_TIME = 20  -- fuel
local STANDBY_TICKS = 4  -- used for blocked state
local COUNTDOWN_TICKS = 2
local OFFSET = 5  -- for uneven terrains

-- start on top of the base block
local function working_start_pos(pos, altitude)
	local working_pos = table.copy(pos)
	working_pos.y = working_pos.y + (altitude or START_HEIGHT)
	return working_pos
end

local Radius2Idx = {[4]=1 ,[6]=2, [8]=3, [10]=4, [12]=5, [14]=6, [16]=7}
local Altitude2Idx = {[-2]=1 ,[-1]=2, [0]=3, [1]=4, [2]=5, [4]=6, [6]=7, [8]=8, [10]=9, [14]=10, [18]=11}

local function formspec(self, pos, meta)
	-- some recalculations
	local this = minetest.deserialize(meta:get_string("this"))
	local endless = this.endless == 1 and "true" or "false"
	local fuel = this.fuel * 100/BURNING_TIME
	if self:get_state(meta) ~= tubelib.RUNNING then
		fuel = 0
	end
	local radius = Radius2Idx[this.radius] or 2
	local altitude = Altitude2Idx[this.altitude or START_HEIGHT] or 11
	
	return "size[9,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"dropdown[0,0;1.5;radius;4,6,8,10,12,14,16;"..radius.."]".. 
	"label[1.6,0.2;"..S("Area radius").."]"..
	"dropdown[0,1;1.5;altitude;-2,-1,0,1,2,4,6,8,10,14,18;"..altitude.."]".. 
	"label[1.6,1.2;"..S("Altitude ").."]"..
	"checkbox[0,2;endless;"..S("Run endless")..";"..endless.."]"..
	"list[context;main;5,0;4,4;]"..
	"list[context;fuel;1.5,3;1,1;]"..
	"item_image[1.5,3;1,1;tubelib_addons1:biofuel]"..
	"image[2.5,3;1,1;default_furnace_fire_bg.png^[lowpart:"..
	fuel..":default_furnace_fire_fg.png]"..
	"image_button[3.5,3;1,1;".. self:get_state_button_image(meta) ..";state_button;]"..
	"list[current_player;main;0.5,4.3;8,4;]"..
	"listring[context;main]"..
	"listring[current_player;main]"
end

local State = tubelib.NodeStates:new({
	node_name_passive = "tubelib_addons1:harvester_base",
	node_name_defect = "tubelib_addons1:harvester_defect",
	infotext_name = S("Tubelib Harvester"),
	cycle_time = CYCLE_TIME,
	standby_ticks = STANDBY_TICKS,
	has_item_meter = true,
	aging_factor = 15,
	on_start = function(pos, meta, oldstate)
		local this = minetest.deserialize(meta:get_string("this"))
		this.idx = 0
		this.working_pos = working_start_pos(pos, this.altitude)
		meta:set_string("this", minetest.serialize(this))
	end,
	formspec_func = formspec,
})

local function gen_working_steps()
	-- Working steps like a snail shell from inner to outer
	local t = {}
	for steps = 1,MAX_DIAMETER,2 do
		for idx = 1,steps do
			t[#t+1] = 0
		end
		for idx = 1,steps do
			t[#t+1] = 1
		end
		steps = steps + 1
		for idx = 1,steps do
			t[#t+1] = 2
		end
		for idx = 1,steps do
			t[#t+1] = 3
		end
	end
	return t
end		

local WorkingSteps = gen_working_steps()


local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local inv = M(pos):get_inventory()
	if listname == "main" then
		return stack:get_count()
	elseif listname == "fuel" and tubelib.is_fuel(stack) then
		return stack:get_count()
	end
	return 0
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function get_next_pos(old_pos, idx)
	local facedir = WorkingSteps[idx]
	return vector.add(old_pos, core.facedir_to_dir(facedir))
end

-- Remove saplings lying arround
local function remove_all_sapling_items(pos)
	for _, object in pairs(minetest.get_objects_inside_radius(pos, 4)) do
		local lua_entity = object:get_luaentity()
		if not object:is_player() and lua_entity and lua_entity.name == "__builtin:item" then
			object:remove()
		end
	end
end

local function is_plantable_ground(node)
	if minetest.get_item_group(node.name, "soil") ~= 0 then
		return true
	end
	if minetest.get_item_group(node.name, "sand") ~= 0 then
		return true
	end
	return false
end

-- Remove wood/leave nodes and place sapling if necessary
-- Return false if inventory is full
-- else return true
local function remove_or_replace_node(this, pos, inv, node, order)
	local next_pos = table.copy(pos)
	next_pos.y = next_pos.y - 1
	
	-- Not enough space in the inventory
	if not inv:room_for_item("main", ItemStack(node.name)) then
		return false
	end
	local next_node = minetest.get_node_or_nil(next_pos)
	if next_node then
		minetest.remove_node(pos)
		inv:add_item("main", ItemStack(order.drop))
		this.num_items = this.num_items + 1
		if is_plantable_ground(next_node) and order.plant then  -- hit the ground?
			minetest.set_node(pos, {name=order.plant, paramtype2 = "wallmounted", param2=1})
			if order.t1 ~= nil then 
				-- We have to simulate "on_place" and start the timer by hand
				-- because the after_place_node function checks player rights and can't therefore
				-- be used.
				minetest.get_node_timer(pos):start(math.random(order.t1, order.t2))
			end
			remove_all_sapling_items(pos)
		end
	end
	return true
end	

-- check the fuel level and return false if empty
local function check_fuel(pos, this, meta)
	if this.fuel <= 0 then
		local fuel_item = tubelib.get_this_item(meta, "fuel", 1)
		if fuel_item == nil then
			return false
		end
		if not tubelib.is_fuel(fuel_item) then
			tubelib.put_item(meta, "fuel", fuel_item)
			return false
		end
		this.fuel = BURNING_TIME
	else
		this.fuel = this.fuel - 1
	end
	return true
end

local function calc_new_pos(pos, this, meta)
	this.idx = this.idx + 1
	if this.idx >= this.max then
		if this.endless == 1 then
			this.idx = 0
			this.working_pos = working_start_pos(pos, this.altitude)
			return true
		else
			return false
		end
	end
	this.working_pos = get_next_pos(this.working_pos, this.idx)
	return true
end

-- Scan the space below the given position
-- Return false if inventory is full
-- else return true
local function harvest_field(this, meta)
	local inv = meta:get_inventory()
	local pos = table.copy(this.working_pos)
	local start_y_pos = pos.y - 1
	local stop_y_pos = pos.y - (this.altitude or START_HEIGHT) - OFFSET
	if minetest.is_protected(pos, this.owner) then
		return true
	end
	for y_pos = start_y_pos,stop_y_pos,-1 do
		pos.y = y_pos
		local node = minetest.get_node_or_nil(pos)
		if node and node.name ~= "air" then
			local order = tubelib_addons1.FarmingNodes[node.name] or tubelib_addons1.Flowers[node.name]
			if order then
				if not minetest.is_protected(pos, this.owner) and not remove_or_replace_node(this, pos, inv, node, order) then
					return false
				end
			else 	
				return true	-- hit the ground
			end
		end
	end
	return true
end

local function not_blocked(pos, this, meta)
	if State:get_state(meta) == tubelib.BLOCKED then
		if harvest_field(this, meta) then
			minetest.after(0, State.start, State, pos, meta)
		end
		return false
	end
	return true
end
	
-- move the "harvesting copter" to the next pos and harvest the field below
local function keep_running(pos, elapsed)
	if tubelib.data_not_corrupted(pos) then
		local meta = M(pos)
		local this = minetest.deserialize(meta:get_string("this"))
		this.num_items = 0
		
		if not_blocked(pos, this, meta) then
			if check_fuel(pos, this, meta) then
				if calc_new_pos(pos, this, meta) then
					if harvest_field(this, meta) then
						meta:set_string("this", minetest.serialize(this))
						meta:set_string("infotext", 
							S("Tubelib Harvester").." "..this.number..
							S(": running (")..this.idx.."/"..this.max..")")
						State:keep_running(pos, meta, COUNTDOWN_TICKS, this.num_items)
					else
						State:blocked(pos, meta)
					end
				else
					State:stop(pos, meta)
				end
			else
				State:fault(pos, meta)
			end
		end
		return State:is_active(meta)
	end
	return false
end	
	

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local meta = M(pos)
	local this = minetest.deserialize(meta:get_string("this"))
	local radius = this.radius
	local altitude = this.altitude or START_HEIGHT
	
	if fields.radius ~= nil then
		radius = tonumber(fields.radius)
	end
	if radius ~= this.radius then
		this.radius = radius
		this.max = (radius*2 + 1) * (radius*2 + 1)
		meta:set_string("this", minetest.serialize(this))
		State:stop(pos, meta)
	end

	if fields.altitude ~= nil then
		altitude = tonumber(fields.altitude)
	end
	if altitude ~= this.altitude then
		this.altitude = altitude
		meta:set_string("this", minetest.serialize(this))
		State:stop(pos, meta)
	end
	
	if fields.endless ~= nil then
		this.endless = fields.endless == "true" and 1 or 0
	end
	meta:set_string("this", minetest.serialize(this))
	
	State:state_button_event(pos, fields)
end

minetest.register_node("tubelib_addons1:harvester_base", {
	description = S("Tubelib Harvester Base"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_addons1_harvester.png',
	},

	after_place_node = function(pos, placer)
		local meta = M(pos)
		local inv = meta:get_inventory()
		inv:set_size('main', 16)
		inv:set_size('fuel', 1)
		local number = tubelib.add_node(pos, "tubelib_addons1:harvester_base")
		local this = {
			number = number,
			owner = placer:get_player_name(),
			working_pos = working_start_pos(pos, START_HEIGHT),
			fuel = 0,
			endless = 0,
			radius = 6,
			idx = 0,
			max = (6+1+6) * (6+1+6)
		}
		meta:set_string("this", minetest.serialize(this))
		State:node_init(pos, number)
	end,

	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local inv = M(pos):get_inventory()
		return inv:is_empty("main") and inv:is_empty("fuel")
	end,

	on_dig = function(pos, node, player)
		State:on_dig_node(pos, node, player)
		tubelib.remove_node(pos)
	end,
	
	on_rotate = screwdriver.disallow,
	on_receive_fields = on_receive_fields,
	on_timer = keep_running,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("tubelib_addons1:harvester_defect", {
	description = S("Tubelib Harvester Base"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_addons1_harvester.png^tubelib_defect.png',
	},

	on_construct = function(pos)
		local inv = M(pos):get_inventory()
		inv:set_size('main', 16)
		inv:set_size('fuel', 1)
	end,
	
	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons1:harvester_base")
		local this = {
			number = number,
			owner = placer:get_player_name(),
			working_pos = working_start_pos(pos, START_HEIGHT),
			fuel = 0,
			endless = 0,
			radius = 6,
			idx = 0,
			max = (6+1+6) * (6+1+6)
		}
		local meta = M(pos)
		meta:set_string("this", minetest.serialize(this))
		State:node_init(pos, number)
		State:defect(pos, meta)
	end,

	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local inv = M(pos):get_inventory()
		return inv:is_empty("main") and inv:is_empty("fuel")
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		tubelib.remove_node(pos)
	end,

	on_rotate = screwdriver.disallow,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_craft({
	output = "tubelib_addons1:harvester_base",
	recipe = {
		{"default:steel_ingot", "default:mese_crystal", "default:steel_ingot"},
		{"default:steel_ingot", "default:mese_crystal",	"tubelib:tubeS"},
		{"group:wood", 			"default:mese_crystal", "group:wood"},
	},
})


tubelib.register_node("tubelib_addons1:harvester_base", {"tubelib_addons1:harvester_defect"}, {
	on_pull_stack = function(pos, side)
		return tubelib.get_stack(M(pos), "main")
	end,
	on_pull_item = function(pos, side)
		return tubelib.get_item(M(pos), "main")
	end,
	on_push_item = function(pos, side, item)
		if not tubelib.is_fuel(item) then
			return false
		end
		return tubelib.put_item(M(pos), "fuel", item)
	end,
	on_unpull_item = function(pos, side, item)
		return tubelib.put_item(M(pos), "main", item)
	end,
	on_recv_message = function(pos, topic, payload)
		if topic == "fuel" then
			return tubelib.fuelstate(M(pos), "fuel")
		end
		
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


-- update to v0.08
minetest.register_lbm({
	label = "[tubelib_addons1] Harvester update",
	name = "tubelib_addons1:update",
	nodenames = {"tubelib_addons1:harvester_base", "tubelib:harvester_base_active"},
	run_at_every_load = false,
	action = function(pos, node)
		local meta = M(pos)
		local this = minetest.deserialize(meta:get_string("this"))
		if this then
			this.working_pos = this.copter_pos or working_start_pos(pos, this.altitude)
			meta:set_string("this", minetest.serialize(this))
		end
	end
})

