--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017,2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	harvester.lua
	
	Harvester machine to chop wood, leaves and harvest farming crops.
	
	The machine is able to harvest an square area of up to 33x33 blocks (radius = 16).
	The base node has to be placed in the middle of the harvesting area.
	The Harvester processes one node every 4 seconds.
	It requires one item Bio Fuel per 20 nodes.

]]--


local CYCLE_TIME = 4
local MAX_HEIGHT = 18
local MAX_DIAMETER = 33
local BURNING_TIME = 20
local TICKS_TO_SLEEP = 10
local STOP_STATE = 0
local RUNNING = 1
local STANDBY_STATE = -1
local FAULT_STATE = -3
local OFFSET = 5

local Radius2Idx = {[4]=1 ,[6]=2, [8]=3, [10]=4, [12]=5, [14]=6, [16]=7}

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


local function formspec(this, state)
	-- some recalculations
	local endless = this.endless == 1 and "true" or "false"
	local fuel = this.fuel * 100/BURNING_TIME
	if state ~= tubelib.RUNNING then
		fuel = 0
	end
	local radius = Radius2Idx[this.radius] or 2
	
	return "size[9,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"dropdown[0,0;1.5;radius;4,6,8,10,12,14,16;"..radius.."]".. 
	"label[1.6,0.2;Area radius]"..
	"checkbox[0,1;endless;Run endless;"..endless.."]"..
	"list[context;main;5,0;4,4;]"..
	"list[context;fuel;1.5,3;1,1;]"..
	"item_image[1.5,3;1,1;tubelib_addons1:biofuel]"..
	"image[2.5,3;1,1;default_furnace_fire_bg.png^[lowpart:"..
	fuel..":default_furnace_fire_fg.png]"..
	"image_button[3.5,3;1,1;".. tubelib.state_button(state) ..";button;]"..
	"list[current_player;main;0.5,4.3;8,4;]"..
	"listring[context;main]"..
	"listring[current_player;main]"
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if listname == "main" then
		return stack:get_count()
	elseif listname == "fuel" and stack:get_name() == "tubelib_addons1:biofuel" then
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

-- start on top of the base block
local function working_start_pos(pos)
	local working_pos = table.copy(pos)
	working_pos.y = working_pos.y + MAX_HEIGHT
	return working_pos
end

local function get_next_pos(old_pos, idx)
	local facedir = WorkingSteps[idx]
	return vector.add(old_pos, core.facedir_to_dir(facedir))
end

local function start_the_machine(pos, this, meta)
	this.running = RUNNING
	this.working_pos = working_start_pos(pos)
	meta:set_string("infotext", "Tubelib Harvester "..this.number..": running")
	meta:set_string("formspec", formspec(this, tubelib.RUNNING))
	minetest.get_node_timer(pos):start(CYCLE_TIME)
	meta:set_string("this", minetest.serialize(this))
	return false
end

local function stop_the_machine(pos, this, meta)
	this.running = STOP_STATE
	this.idx = 0
	meta:set_string("infotext", "Tubelib Harvester "..this.number..": stopped")
	meta:set_string("formspec", formspec(this, tubelib.STOPPED))
	minetest.get_node_timer(pos):stop()
	meta:set_string("this", minetest.serialize(this))
	return false
end

local function goto_standby(pos, this, meta)
	this.running = STANDBY_STATE
	meta:set_string("infotext", "Tubelib Harvester "..this.number..": standby")
	meta:set_string("formspec", formspec(this, tubelib.STANDBY))
	minetest.get_node_timer(pos):start(CYCLE_TIME * TICKS_TO_SLEEP)
	meta:set_string("this", minetest.serialize(this))
	return false
end

local function goto_fault(pos, this, meta)
	this.running = FAULT_STATE
	meta:set_string("infotext", "Tubelib Harvester "..this.number..": fault")
	meta:set_string("formspec", formspec(this, tubelib.FAULT))
	minetest.get_node_timer(pos):stop()
	meta:set_string("this", minetest.serialize(this))
	return false
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

-- Remove wood/leave nodes and place sapling if necessary
-- Return false if inventory is full
-- else return true
local function remove_or_replace_node(pos, inv, node, order)
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
		if tubelib_addons1.GroundNodes[next_node.name] ~= nil and order.plant then  -- hit the ground?
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
		if tubelib.get_this_item(meta, "fuel", 1) == nil then
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
			this.working_pos = working_start_pos(pos)
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
	local stop_y_pos = pos.y - MAX_HEIGHT - OFFSET
	if minetest.is_protected(pos, this.owner) then
		return true
	end
	for y_pos = start_y_pos,stop_y_pos,-1 do
		pos.y = y_pos
		local node = minetest.get_node_or_nil(pos)
		if node and node.name ~= "air" then
			local order = tubelib_addons1.FarmingNodes[node.name]
			if order then
				if not remove_or_replace_node(pos, inv, node, order) then
					return false
				end
			else 	
				return true	-- hit the ground
			end
		end
	end
	return true
end

local function not_standby(pos, this, meta)
	if this and this.running == STANDBY_STATE then
		if harvest_field(this, meta) then
			minetest.after(0, start_the_machine, pos, this, meta)
		end
		return false
	end
	return true
end
	
-- move the copter to the next pos and harvest the field below
local function keep_running(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local this = minetest.deserialize(meta:get_string("this"))
	
	--print(this.working_pos.x, this.working_pos.z, this.running)
	if not_standby(pos, this, meta) then
		if check_fuel(pos, this, meta) then
			if calc_new_pos(pos, this, meta) then
				if harvest_field(this, meta) then
					meta:set_string("this", minetest.serialize(this))
					meta:set_string("infotext", 
						"Tubelib Harvester "..this.number..
						": running ("..this.idx.."/"..this.max..")")
					return true
				else
					goto_standby(pos, this, meta)
				end
			else
				stop_the_machine(pos, this, meta)
			end
		else
			goto_fault(pos, this, meta)
		end
		return false
	end
	return true
end	
	

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local meta = minetest.get_meta(pos)
	local this = minetest.deserialize(meta:get_string("this"))
	local radius = this.radius
	
	if fields.radius ~= nil then
		radius = tonumber(fields.radius)
	end
	if radius ~= this.radius then
		stop_the_machine(pos, this, meta)
		this.radius = radius
		this.max = (radius*2 + 1) * (radius*2 + 1)
	end

	if fields.endless ~= nil then
		this.endless = fields.endless == "true" and 1 or 0
	end
	
	if fields.button ~= nil then
		if this.running > STOP_STATE then
			stop_the_machine(pos, this, meta)
		else
			start_the_machine(pos, this, meta)
		end
	else
		meta:set_string("formspec", formspec(this, tubelib.state(this.running)))
	end
	meta:set_string("this", minetest.serialize(this))
end

minetest.register_node("tubelib_addons1:harvester_base", {
	description = "Tubelib Harvester Base",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_addons1_harvester.png',
	},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size('main', 16)
		inv:set_size('fuel', 1)
	end,
	
	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons1:harvester_base")
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Tubelib Harvester "..number..": stopped")
		local this = {
			number = number,
			owner = placer:get_player_name(),
			working_pos = working_start_pos(pos),
			fuel = 0,
			running = STOP_STATE,
			endless = 0,
			radius = 6,
			idx = 0,
			max = (6+1+6) * (6+1+6)
		}
		meta:set_string("this", minetest.serialize(this))
		meta:set_string("formspec", formspec(this, tubelib.STOPPED))
	end,

	on_dig = function(pos, node, puncher, pointed_thing)
		if minetest.is_protected(pos, puncher:get_player_name()) then
			return
		end
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if inv:is_empty("main") then
			minetest.node_dig(pos, node, puncher, pointed_thing)
			tubelib.remove_node(pos)
		end
	end,

	on_rotate = screwdriver.disallow,
	on_receive_fields = on_receive_fields,
	on_timer = keep_running,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype = "light",
	sunlight_propagates = true,
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("tubelib_addons1:harvester_base_active", {
	description = "Tubelib Harvester Base",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_addons1_harvester.png',
	},

	on_rotate = screwdriver.disallow,
	on_receive_fields = on_receive_fields,
	on_timer = keep_running,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype = "light",
	sunlight_propagates = true,
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	output = "tubelib_addons1:harvester_base",
	recipe = {
		{"default:steel_ingot", "default:mese_crystal", "default:steel_ingot"},
		{"default:steel_ingot", "default:mese_crystal",	"tubelib:tube1"},
		{"group:wood", 			"default:mese_crystal", "group:wood"},
	},
})


tubelib.register_node("tubelib_addons1:harvester_base", {}, {
	on_pull_stack = function(pos, side)
		local meta = minetest.get_meta(pos)
		return tubelib.get_stack(meta, "main")
	end,
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		return tubelib.get_item(meta, "main")
	end,
	on_push_item = function(pos, side, item)
		if item:get_name() == "tubelib_addons1:biofuel" then
			local meta = minetest.get_meta(pos)
			return tubelib.put_item(meta, "fuel", item)
		end
		return false
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
	on_recv_message = function(pos, topic, payload)
		local meta = minetest.get_meta(pos)
		local this = minetest.deserialize(meta:get_string("this"))
		if topic == "on" then
			start_the_machine(pos, this, meta)
		elseif topic == "off" then
			stop_the_machine(pos, this, meta)
		elseif topic == "state" then
			return tubelib.statestring(this.running)
		elseif topic == "fuel" then
			local meta = minetest.get_meta(pos)
			return tubelib.fuelstate(meta, "fuel")
		else
			return "unsupported"
		end
	end,
})	


-- update to v0.08
minetest.register_lbm({
	label = "[tubelib_addons1] Harvester update",
	name = "tubelib_addons1:update",
	nodenames = {"tubelib_addons1:harvester_base", "tubelib:harvester_base_active"},
	run_at_every_load = false,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		local this = minetest.deserialize(meta:get_string("this"))
		if this then
			this.working_pos = this.copter_pos or working_start_pos(pos)
			meta:set_string("this", minetest.serialize(this))
		end
	end
})

