--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	command.lua:

  See [api.md] for the interface documentation

]]--

-------------------------------------------------------------------
-- Data base storage
-------------------------------------------------------------------
local storage = minetest.get_mod_storage()
local NextNumber = minetest.deserialize(storage:get_string("NextNumber")) or 1
local Version = minetest.deserialize(storage:get_string("Version")) or 1
local Number2Pos = minetest.deserialize(storage:get_string("Number2Pos")) or {}

local function update_mod_storage()
	storage:set_string("NextNumber", minetest.serialize(NextNumber))
	storage:set_string("Version", minetest.serialize(Version))
	storage:set_string("Number2Pos", minetest.serialize(Number2Pos))
	storage:set_string("Key2Number", nil) -- not used any more 
	-- store data each hour
	minetest.after(60*60, update_mod_storage)
	print("[Tubelib] Data stored")
end

minetest.register_on_shutdown(function()
	update_mod_storage()
end)

-- store data after one hour
minetest.after(60*60, update_mod_storage)

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
local get_neighbor_pos = tubelib.get_neighbor_pos
local read_node_with_vm = tubelib.read_node_with_vm

-- Translate from facedir to contact side of the other node
-- (left for one is right for the other node)
local FacedirToSide = {[0] = "F", "L", "B", "R", "U", "D"}

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

-- Determine the contact side of the node at the given pos
-- param facedir: facedir to the node
local function get_node_side(npos, facedir)	
	local node = minetest.get_node_or_nil(npos) or read_node_with_vm(npos)
	if facedir < 4 then
		facedir = (facedir - node.param2 + 4) % 4
	end
	return FacedirToSide[facedir], node
end

local function generate_Key2Number()
	local key
	for num,item in pairs(Number2Pos) do
		key = get_key_str(item.pos)
		Key2Number[key] = num
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
	
-- Add node to the tubelib lists and update the tube surrounding.
-- Function determines and returns the node position number,
-- needed for message communication.
function tubelib.add_node(pos, name)
	-- store position 
	local number = get_number(pos)
	Number2Pos[number] = {
		pos = pos, 
		name = name,
	}
	-- update surrounding tubes
	tubelib.update_tubes(pos)
	return number
end

-- Function removes the node from the tubelib lists.
function tubelib.remove_node(pos)
	local number = get_number(pos)
	if Number2Pos[number] then
		Number2Pos[number] = {
			pos = pos, 
			name = nil,
			time = minetest.get_day_count() -- used for aging
		}
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
--    }
function tubelib.register_node(name, add_names, node_definition)
	tubelib_NodeDef[name] = node_definition
	-- store facedir table for all known node names
	tubelib.knownNodes[name] = true
	Name2Name[name] = name
	for _,n in ipairs(add_names) do
		tubelib.knownNodes[n] = true
		Name2Name[n] = name
	end
end

-------------------------------------------------------------------
-- Send message functions
-------------------------------------------------------------------

function tubelib.send_message(numbers, placer_name, clicker_name, topic, payload)
	for _,num in ipairs(string_split(numbers, " ")) do
		if Number2Pos[num] and Number2Pos[num].name then
			local data = Number2Pos[num]
			if placer_name and not minetest.is_protected(data.pos, placer_name) then
				if clicker_name == nil or not minetest.is_protected(data.pos, clicker_name) then
					if data and data.name then
						if tubelib_NodeDef[data.name] and tubelib_NodeDef[data.name].on_recv_message then
							tubelib_NodeDef[data.name].on_recv_message(data.pos, topic, payload)
						end
					end
				end
			end
		end
	end
end		

function tubelib.send_request(number, topic, payload)
	if Number2Pos[number] and Number2Pos[number].name then
		local data = Number2Pos[number]
		if data and data.name then
			if tubelib_NodeDef[data.name] and tubelib_NodeDef[data.name].on_recv_message then
				return tubelib_NodeDef[data.name].on_recv_message(data.pos, topic, payload)
			end
		end
	end
	return false
end		

-------------------------------------------------------------------
-- Client side Push/Pull item functions
-------------------------------------------------------------------

function tubelib.pull_items(pos, side, player_name)
	local npos, facedir = get_neighbor_pos(pos, side)
	local nside, node = get_node_side(npos, facedir)
	local name = Name2Name[node.name]
	if tubelib_NodeDef[name] and tubelib_NodeDef[name].on_pull_item then
		return tubelib_NodeDef[name].on_pull_item(npos, nside, player_name)
	end
	return nil
end

function tubelib.push_items(pos, side, items, player_name)
	local npos, facedir = get_neighbor_pos(pos, side)
	local nside, node = get_node_side(npos, facedir)
	local name = Name2Name[node.name]
	if tubelib_NodeDef[name] and tubelib_NodeDef[name].on_push_item then
		return tubelib_NodeDef[name].on_push_item(npos, nside, items, player_name)	
	elseif node.name == "air" then
		minetest.add_item(npos, items)
		return true 
	end
	return false
end

function tubelib.unpull_items(pos, side, items, player_name)
	local npos, facedir = get_neighbor_pos(pos, side)
	local nside, node = get_node_side(npos, facedir)
	local name = Name2Name[node.name]
	if tubelib_NodeDef[name] and tubelib_NodeDef[name].on_unpull_item then
		return tubelib_NodeDef[name].on_unpull_item(npos, nside, items, player_name)
	end
	return false
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

-- Get one item from the given ItemList, specified by stack number (1..n).
-- Returns nil if ItemList is empty.
function tubelib.get_this_item(meta, listname, number)
	if meta == nil or meta.get_inventory == nil then return nil end
	local inv = meta:get_inventory()
	if inv:is_empty(listname) then
		return nil
	end
	
	local items = inv:get_stack(listname, number)
	if items:get_count() > 0 then
		local taken = items:take_item(1)
		inv:set_stack(listname, number, items)
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
	


-------------------------------------------------------------------------------
-- Data Maintenance
-------------------------------------------------------------------------------
local function data_maintenance()
	print("[Tubelib] Data maintenance started")
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
			elseif item.time and (item.time + 360) > day_cnt then
				Number2Pos[num] = item
			else
				print("Position deleted", num)
			end
		end
	end
	print("[Tubelib] Data maintenance finished")
end	
	
generate_Key2Number()

-- maintain data after one minute
-- (minetest.get_day_count() will not be valid at start time)
minetest.after(60, data_maintenance)


