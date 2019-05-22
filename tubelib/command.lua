--[[

	Tube Library
	============

	Copyright (C) 2017-2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	command.lua:

  See [api.md] for the interface documentation

]]--

--- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

------------------------------------------------------------------
-- Data base storage
-------------------------------------------------------------------
local storage = minetest.get_mod_storage()
local NextNumber = minetest.deserialize(storage:get_string("NextNumber")) or 1
local Version = minetest.deserialize(storage:get_string("Version")) or 1
local Number2Pos = minetest.deserialize(storage:get_string("Number2Pos")) or {}

local function update_mod_storage()
	minetest.log("action", "[Tubelib] Store data...")
	storage:set_string("NextNumber", minetest.serialize(NextNumber))
	storage:set_string("Version", minetest.serialize(Version))
	storage:set_string("Number2Pos", minetest.serialize(Number2Pos))
	storage:set_string("Key2Number", nil) -- not used any more 
	-- store data each hour
	minetest.after(60*59, update_mod_storage)
	minetest.log("action", "[Tubelib] Data stored")
end

minetest.register_on_shutdown(function()
	update_mod_storage()
end)

-- store data after one hour
minetest.after(60*59, update_mod_storage)

-- Key2Number will be generated at runtine
local Key2Number = {} 

local Name2Name = {}		-- translation table

-------------------------------------------------------------------
-- Local helper functions
-------------------------------------------------------------------

-- Localize functions to avoid table lookups (better performance).
local string_find = string.find
local string_split = string.split
local tubelib_NodeDef = tubelib.NodeDef
local Tube = tubelib.Tube

-- Generate a key string based on the given pos table,
-- Used internaly as table key,
local function get_key_str(pos)
	pos = minetest.pos_to_string(pos)
	return string.sub(pos, 2, -2)
end

-- Determine position related node number for addressing purposes
local function get_number(pos)
	local key = get_key_str(pos)
	if not Key2Number[key] then
		Key2Number[key] = NextNumber
		NextNumber = NextNumber + 1
	end
	return string.format("%.04u", Key2Number[key])
end

local function generate_Key2Number()
	local key
	for num,item in pairs(Number2Pos) do
		key = get_key_str(item.pos)
		Key2Number[key] = num
	end
end

local function not_protected(pos, placer_name, clicker_name)
	local meta = minetest.get_meta(pos)
	if meta then
		local cached_name = meta:get_string("tubelib_cached_name")
		if placer_name and (placer_name == cached_name or not minetest.is_protected(pos, placer_name)) then
			meta:set_string("tubelib_cached_name", placer_name)
			if clicker_name == nil or not minetest.is_protected(pos, clicker_name) then
				return true
			end
		end
	end
	return false
end

local function register_lbm(name, nodenames)
	minetest.register_lbm({
		label = "[Tubelib] Node update",
		name = name.."update",
		nodenames = nodenames,
		run_at_every_load = true,
		action = function(pos, node)
			local name = Name2Name[node.name]
			if tubelib_NodeDef[name] and tubelib_NodeDef[name].on_node_load then
				tubelib_NodeDef[name].on_node_load(pos)
			end
		end
	})
end


local DirToSide = {"B", "R", "F", "L", "D", "U"}

local function dir_to_side(dir, param2)
	if dir < 5 then
		dir = (((dir - 1) - (param2 % 4)) % 4) + 1
	end
	return DirToSide[dir]
end

local SideToDir = {B=1, R=2, F=3, L=4, D=5, U=6}

local function side_to_dir(side, param2)
	local dir = SideToDir[side]
	if dir < 5 then
		dir = (((dir - 1) + (param2 % 4)) % 4) + 1
	end
	return dir
end

local function get_dest_node(pos, side)
	local _,node = Tube:get_node(pos)
	local dir = side_to_dir(side, node.param2)
	local spos, sdir = Tube:get_connected_node_pos(pos, dir)
	_,node = Tube:get_node(spos)
	local out_side = dir_to_side(tubelib2.Turn180Deg[sdir], node.param2)
	return spos, out_side, Name2Name[node.name] or node.name 
end
	
local function item_handling_node(name)
	local node_def = name and tubelib_NodeDef[name]
	if node_def then
		return node_def.on_pull_item or node_def.on_push_item or node_def.is_pusher
	end
end

-------------------------------------------------------------------
-- API helper functions
-------------------------------------------------------------------
	
-- Check the given list of numbers.
-- Returns true if number(s) is/are valid and point to real nodes.
function tubelib.check_numbers(numbers)
	if numbers then
		for _,num in ipairs(string_split(numbers, " ")) do
			if Number2Pos[num] == nil then
				return false
			end
		end
		return true
	end
	return false
end	

-- Function returns { pos, name } for the node on the given position number.
function tubelib.get_node_info(dest_num)
	if Number2Pos[dest_num] then
		return Number2Pos[dest_num]
	end
	return nil
end	

-- Function returns the node number from the given position or
-- nil, if no node number for this position is assigned.
function tubelib.get_node_number(pos)
	local key = get_key_str(pos)
	local num = Key2Number[key]
	if num then
		num = string.format("%.04u", num)
		if Number2Pos[num] and Number2Pos[num].name then
			return num
		end
	end
	return nil
end	

-- Function is used for available nodes with lost numbers, only.
function tubelib.get_new_number(pos, name)
	-- store position 
	local number = get_number(pos)
	Number2Pos[number] = {
		pos = pos, 
		name = name,
	}
	return number
end


-- Store any node number related, additional data
-- param number: node number, returned by tubelib.add_node
-- param name: name of the data (string)
-- param data: any data (number, string, table)
function tubelib.set_data(number, name, data)
	if Number2Pos[number] and type(name) == "string" then
		Number2Pos[number]["u_"..name] = data
	end
end

-- Read node number related data
-- param number: node number, returned by tubelib.add_node
-- param name: name of the data (string)
function tubelib.get_data(number, name)
	if Number2Pos[number] and type(name) == "string" then
		return Number2Pos[number]["u_"..name]
	end
	return nil
end

-------------------------------------------------------------------
-- Node construction/destruction functions
-------------------------------------------------------------------
	
-- Add node to the tubelib lists.
-- Function determines and returns the node position number,
-- needed for message communication.
function tubelib.add_node(pos, name)
	if item_handling_node(name) then
		Tube:after_place_node(pos)
	end
	-- store position 
	local number = get_number(pos)
	Number2Pos[number] = {
		pos = pos, 
		name = name,
	}
	return number
end

-- Function removes the node from the tubelib lists.
function tubelib.remove_node(pos)
	local number = get_number(pos)
	local name
	if Number2Pos[number] then
		name = Number2Pos[number].name
		Number2Pos[number] = {
			pos = pos, 
			name = nil,
			time = minetest.get_day_count() -- used for reservation timeout
		}
	end
	if item_handling_node(name) then
		Tube:after_dig_node(pos)
	end
end


-------------------------------------------------------------------
-- Node register function
-------------------------------------------------------------------

-- Register node for tubelib communication
-- Call this function only at load time!
-- Param name: The node name like "tubelib:pusher"
-- Param add_names: Alternativ node names if needded, e.g.: "tubelib:pusher_active"
-- Param node_definition: A table according to:
--    {
--        on_pull_item = func(pos, side, player_name),
--        on_push_item = func(pos, side, item, player_name),
--        on_unpull_item = func(pos, side, item, player_name),
--        on_recv_message = func(pos, topic, payload),
--        on_node_load = func(pos),  -- LBM function
--        on_node_repair = func(pos),  -- repair defect (feature!) nodes
--    }
function tubelib.register_node(name, add_names, node_definition)
	tubelib_NodeDef[name] = node_definition
	-- store facedir table for all known node names
	Name2Name[name] = name
	for _,n in ipairs(add_names) do
		Name2Name[n] = name
	end
	if node_definition.on_pull_item or node_definition.on_push_item or 
			node_definition.is_pusher then
		Tube:add_secondary_node_names({name})
		Tube:add_secondary_node_names(add_names)
		
		tubelib.KnownNodes[name] = true
		for _,n in ipairs(add_names) do
			tubelib.KnownNodes[n] = true
		end
	end
	-- register LBM
	if node_definition.on_node_load then
		local nodenames = {name}
		for _,n in ipairs(add_names) do
			nodenames[#nodenames + 1] = n
		end
		register_lbm(name, nodenames)
	end
end

-------------------------------------------------------------------
-- Send message functions
-------------------------------------------------------------------

function tubelib.send_message(numbers, placer_name, clicker_name, topic, payload)
	for _,num in ipairs(string_split(numbers, " ")) do
		if Number2Pos[num] and Number2Pos[num].name then
			local data = Number2Pos[num]
			if not_protected(data.pos, placer_name, clicker_name) then
				if tubelib_NodeDef[data.name] and tubelib_NodeDef[data.name].on_recv_message then
					tubelib_NodeDef[data.name].on_recv_message(data.pos, topic, payload)
				end
			end
		end
	end
end		

function tubelib.send_request(number, topic, payload)
	if Number2Pos[number] and Number2Pos[number].name then
		local data = Number2Pos[number]
		if tubelib_NodeDef[data.name] and tubelib_NodeDef[data.name].on_recv_message then
			return tubelib_NodeDef[data.name].on_recv_message(data.pos, topic, payload)
		end
	end
	return false
end		

-- for defect nodes
function tubelib.repair_node(pos)
	local node = minetest.get_node(pos)
	local name = Name2Name[node.name]
	if tubelib_NodeDef[name] and tubelib_NodeDef[name].on_node_repair then
		return tubelib_NodeDef[name].on_node_repair(pos)
	end
	return false
end

-------------------------------------------------------------------
-- Client side Push/Pull item functions
-------------------------------------------------------------------

function tubelib.pull_items(pos, side, player_name)
	local npos, nside, name = get_dest_node(pos, side)
	if npos == nil then return end
	if tubelib_NodeDef[name] and tubelib_NodeDef[name].on_pull_item then
		return tubelib_NodeDef[name].on_pull_item(npos, nside, player_name)
	end
	return nil
end

function tubelib.push_items(pos, side, items, player_name)
	local npos, nside, name = get_dest_node(pos, side)
	if npos == nil then return end
	if tubelib_NodeDef[name] and tubelib_NodeDef[name].on_push_item then
		return tubelib_NodeDef[name].on_push_item(npos, nside, items, player_name)	
	elseif name == "air" then
		minetest.add_item(npos, items)
		return true 
	end
	return false
end

function tubelib.unpull_items(pos, side, items, player_name)
	local npos, nside, name = get_dest_node(pos, side)
	if npos == nil then return end
	if tubelib_NodeDef[name] and tubelib_NodeDef[name].on_unpull_item then
		return tubelib_NodeDef[name].on_unpull_item(npos, nside, items, player_name)
	end
	return false
end
	
function tubelib.pull_stack(pos, side, player_name)
	local npos, nside, name = get_dest_node(pos, side)
	if npos == nil then return end
	if tubelib_NodeDef[name] then
		if tubelib_NodeDef[name].on_pull_stack then
			return tubelib_NodeDef[name].on_pull_stack(npos, nside, player_name)
		elseif tubelib_NodeDef[name].on_pull_item then
			return tubelib_NodeDef[name].on_pull_item(npos, nside, player_name)
		end
	end
	return nil
end

-------------------------------------------------------------------
-- Server side helper functions
-------------------------------------------------------------------

-- Get one item from the given ItemList. The position within the list
-- is incremented each time so that different item stacks will be considered.
-- Returns nil if ItemList is empty.
function tubelib.get_item(meta, listname)
	if meta == nil or meta.get_inventory == nil then return nil end
	local inv = meta:get_inventory()
	if inv:is_empty(listname) then
		return nil
	end
	local size = inv:get_size(listname)
	local startpos = meta:get_int("tubelib_startpos") or 0
	for idx = startpos, startpos+size do
		idx = (idx % size) + 1
		local items = inv:get_stack(listname, idx)
		if items:get_count() > 0 then
			local taken = items:take_item(1)
			inv:set_stack(listname, idx, items)
			meta:set_int("tubelib_startpos", idx)
			return taken
		end
	end
	meta:set_int("tubelib_startpos", 0)
	return nil
end

-- Get one (or more) item(s) from the given ItemList, specified by stack number (1..n).
-- Returns nil if ItemList is empty.
function tubelib.get_this_item(meta, listname, list_number, num_items)
	if meta == nil or meta.get_inventory == nil then return nil end
	local inv = meta:get_inventory()
	if inv:is_empty(listname) then
		return nil
	end
	
	if num_items == nil then num_items = 1 end
	local items = inv:get_stack(listname, list_number)
	if items:get_count() > 0 then
		local taken = items:take_item(num_items)
		inv:set_stack(listname, list_number, items)
		return taken
	end
	return nil
end


-- Put the given item into the given ItemList.
-- Function returns false if ItemList is full.
function tubelib.put_item(meta, listname, item)
	if meta == nil or meta.get_inventory == nil then return false end
	local inv = meta:get_inventory()
	if inv:room_for_item(listname, item) then
		inv:add_item(listname, item)
		return true
	end
	return false
end

-- Take the number of items from the given ItemList.
-- Returns nil if the requested number is not available.
function tubelib.get_num_items(meta, listname, num)
	if meta == nil or meta.get_inventory == nil then return nil end
	local inv = meta:get_inventory()
	if inv:is_empty(listname) then
		return nil
	end
	local size = inv:get_size(listname)
	for idx = 1, size do
		local items = inv:get_stack(listname, idx)
		if items:get_count() >= num then
			local taken = items:take_item(num)
			inv:set_stack(listname, idx, items)
			return taken
		end
	end
	return nil
end

function tubelib.get_stack(meta, listname)
	local inv = meta:get_inventory()
	local item = tubelib.get_item(meta, listname)
	if item and item:get_stack_max() > 1 and inv:contains_item(listname, item) then
		-- try to remove a complete stack
		item:set_count(math.min(98, item:get_stack_max() - 1))
		local taken = inv:remove_item(listname, item)
		-- add the already removed
		taken:set_count(taken:get_count() + 1)
		return taken
	end
	return item 
end

-- Return "full", "loaded", or "empty" depending
-- on the number of fuel stack items.
-- Function only works on fuel inventories with one stacks/99 items
function tubelib.fuelstate(meta, listname, item)
	if meta == nil or meta.get_inventory == nil then return nil end
	local inv = meta:get_inventory()
	if inv:is_empty(listname) then
		return "empty"
	end
	local list = inv:get_list(listname)
	if #list == 1 and list[1]:get_count() == 99 then
		return "full"
	else
		return "loaded"
	end
end
	
-- Return "full", "loaded", or "empty" depending
-- on the inventory load.
-- Full is returned, when no empty stack is available.
function tubelib.get_inv_state(meta, listname)
	if meta == nil or meta.get_inventory == nil then return nil end
	local inv = meta:get_inventory()
	local state
    if inv:is_empty(listname) then
        state = "empty"
    else
        local list = inv:get_list(listname)
        state = "full"
        local num = 0
        for i, item in ipairs(list) do
            if item:is_empty() then
                return "loaded"
            end
        end
    end
    return state
end


-------------------------------------------------------------------------------
-- Data Maintenance
-------------------------------------------------------------------------------
local function data_maintenance()
	minetest.log("info", "[Tubelib] Data maintenance started")
	if Version == 1 then
		-- Add day_count for aging of unused positions
		for num,item in pairs(Number2Pos) do
			if Number2Pos[num].name == nil then
				Number2Pos[num].time = minetest.get_day_count()
			end
		end
		Version = 2
	else
		-- Remove old unused positions
		local Tbl = table.copy(Number2Pos)
		Number2Pos = {}
		local day_cnt = minetest.get_day_count()
		for num,item in pairs(Tbl) do
			if item.name then
				Number2Pos[num] = item
			-- data not older than 5 real days
			elseif item.time and (item.time + (72*5)) > day_cnt then
				Number2Pos[num] = item
			else
				minetest.log("info", "Position deleted", num)
			end
		end
	end
	minetest.log("info", "[Tubelib] Data maintenance finished")
end	
	
generate_Key2Number()

-- maintain data after 5 seconds
-- (minetest.get_day_count() will not be valid at start time)
minetest.after(5, data_maintenance)


