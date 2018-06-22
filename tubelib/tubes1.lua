--[[

	Tube Library
	============

	Copyright (C) 2017-2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua
	
	tubes1.lua: Functions to place and remove tubes

]]--


-- debugging 
local P = minetest.pos_to_string

local MAX_TUBE_LENGTH = 100

-- Conversion from tube number/param2 (number*10 + param2) to tube hole dirs (view from the inside)
local TubeDirs = {
	[10] = {1,3},
	[11] = {2,4},
	[12] = {1,3},
	[13] = {2,4},
	[20] = {5,6},
	[21] = {5,6},
	[22] = {5,6},
	[23] = {5,6},
	[30] = {3,4},
	[31] = {1,4},
	[32] = {1,2},
	[33] = {2,3},
	[40] = {3,5},
	[41] = {4,5},
	[42] = {1,5},
	[43] = {2,5},
	[50] = {3,6},
	[51] = {4,6},
	[52] = {1,6},
	[53] = {2,6},
}

-- Conversion from tube dirs (dir1 * 10 + dir2) to tube number/param2
local TubeNodeAttr = {}

for k,v in pairs(TubeDirs) do
	local key = v[1] * 10 + v[2]
	local number = math.floor(k / 10)
	local param2 = k % 10
	TubeNodeAttr[key] = {number = number, param2 = param2}
end


-- Convertion of 'dir' (view from the outside to inside and vs)
local Turn180Deg = {3,4,1,2,6,5}

local Dir2Offset = {
	{x=0,  y=0,  z=1},
	{x=1,  y=0,  z=0},
	{x=0,  y=0, z=-1},
	{x=-1, y=0,  z=0},
	{x=0,  y=-1, z=0},
	{x=0,  y=1,  z=0}
}

tubelib.TubeNames = {
	["tubelib:tube1"] = true,
	["tubelib:tube2"] = true,
	["tubelib:tube3"] = true,
	["tubelib:tube4"] = true,
	["tubelib:tube5"] = true,
}

-- used for registered nodes
tubelib.KnownNodes = {
	["tubelib:tube1"] = true,
	["tubelib:tube2"] = true,
	["tubelib:tube3"] = true,
	["tubelib:tube4"] = true,
	["tubelib:tube5"] = true,
}

-- use Voxel Manipulator to read the node
function tubelib.read_node_with_vm(pos)
	local vm = VoxelManip()
	local MinEdge, MaxEdge = vm:read_from_map(pos, pos)
	local data = vm:get_data()
	local param2_data = vm:get_param2_data()
	local area = VoxelArea:new({MinEdge = MinEdge, MaxEdge = MaxEdge})
	return {
		name = minetest.get_name_from_content_id(data[area:index(pos.x, pos.y, pos.z)]),
		param2 = param2_data[area:index(pos.x, pos.y, pos.z)]
	}
end

local function get_tube_number_and_param2(dir1, dir2)
	if dir1 == dir2 then
		dir2 = Turn180Deg[dir1]
	end
	if dir1 > dir2 then
		dir1, dir2 = dir2, dir1
	end
	local item = TubeNodeAttr[dir1*10 + dir2]
	return item.number, item.param2
end

-- convert 6D-dir to position
local function get_tube_pos(pos, dir)
	return vector.add(pos, Dir2Offset[dir])
end

-- Tube open sides
local function get_tube_dirs(pos, node)
	if node == nil then
		node = minetest.get_node_or_nil(pos) or tubelib.read_node_with_vm(pos)
	end
	if tubelib.TubeNames[node.name] then
		local ttype = (string.byte(node.name, -1) - 48) * 10 + node.param2
		return TubeDirs[ttype][1], TubeDirs[ttype][2]
	end
	return nil, nil
end
	
function tubelib.get_next_tube(pos, dir)
	pos = get_tube_pos(pos, dir)
	local dir1, dir2 = get_tube_dirs(pos)
	
	if dir1 then
		dir = Turn180Deg[dir]
		if dir == dir1 then
			return pos, dir2
		elseif dir == dir2 then
			return pos, dir1
		end
	end
	return pos, nil
end

local function is_known_node(pos, dir)
	if dir then
		pos = get_tube_pos(pos, dir)
		local node = minetest.get_node_or_nil(pos) or tubelib.read_node_with_vm(pos)
		if tubelib.KnownNodes[node.name] and not tubelib.TubeNames[node.name] then
			return true
		end
	end
	return false
end


-- Walk to the other end of the tube line, starting at 'pos/dir'.
-- Returns: cnt - number of tube nodes
--          pos - the peer tube node
--          dir - dir to the drop position, next after 'pos'
function tubelib.walk_to_peer(pos, dir)
	local cnt = 0
	while cnt < MAX_TUBE_LENGTH do
		local new_pos, new_dir = tubelib.get_next_tube(pos, dir)
		if not new_dir then
			break
		end
		cnt = cnt + 1
		pos, dir = new_pos, new_dir
	end
	return cnt, pos, dir
end	
	
-- Delete meta data of the peer node
function tubelib.delete_meta_data(pos, node)
	local dir1, dir2 = get_tube_dirs(pos, node)
	local cnt1 = 0
	local dir
	if dir1 then
		cnt1, pos, dir = tubelib.walk_to_peer(pos, dir1)
		-- delete meta on peer tube
		if cnt1 > 0 then
			minetest.get_meta(pos):from_table(nil)
		end
	end
	local cnt2 = 0
	if dir2 then
		cnt2, pos, dir = tubelib.walk_to_peer(pos, dir2)
		-- delete meta on peer tube
		if cnt2 > 0 then
			minetest.get_meta(pos):from_table(nil)
		end
	end
	return cnt1 + cnt2
end

local function swap_node(pos, node_num, param2)
	local node = minetest.get_node(pos)
	node.name = "tubelib:tube"..node_num
	node.param2 = param2
	minetest.swap_node(pos, node)
end	

local function is_connected(pos, dir)
	if dir then
		pos = get_tube_pos(pos, dir)
		local dir1,dir2 = get_tube_dirs(pos)
		-- return true if connected
		dir = Turn180Deg[dir]
		return dir == dir1 or dir == dir2 
	end
	return false
end

local function is_tubelib_block(pos, dir)
	if dir then
		pos = get_tube_pos(pos, dir)
		local dir1,dir2 = get_tube_dirs(pos)
		-- return true if connected
		dir = Turn180Deg[dir]
		return dir == dir1 or dir == dir2
	end
	return false
end
local function update_next_tube(dir, pos)
	-- test if tube is connected with neighbor tubes
	local dir1, dir2 = get_tube_dirs(pos)
	local conn1 = is_connected(pos, dir1) or is_known_node(pos, dir1)
	local conn2 = is_connected(pos, dir2) or is_known_node(pos, dir2)
	-- already connected or no tube arround?
	if conn1 == conn2 then
		return
	end
	if conn1 then 
		dir2 = Turn180Deg[dir]
	else
		dir1 = Turn180Deg[dir]
	end
	local node_num, param2 = get_tube_number_and_param2(dir1, dir2)
	swap_node(pos, node_num, param2)
end	
	
-- update new placed tube
local function update_tube(pos, dir)
	local dir1 = nil
	local dir2 = nil
	-- search on all 6 pos for up to 2 tubes with open holes or 
	-- other tubelib compatible nodes
	for dir = 1,6 do
		if not dir1 and is_connected(pos, dir) then
			dir1 = dir
		elseif not dir2 and is_connected(pos, dir) then
			dir2 = dir
		end
	end
	if not dir1 or not dir2 then
		for dir = 1,6 do
			if not dir1 and is_known_node(pos, dir) then 
				dir1 = dir
			elseif not dir2 and is_known_node(pos, dir) then 
				dir2 = dir
			end
		end
	end
	dir1 = dir1 or dir 
	dir2 = dir2 or Turn180Deg[dir]
	local node_num, param2 = get_tube_number_and_param2(dir1, dir2)
	swap_node(pos, node_num, param2)
end

function tubelib.update_tubes(pos, dir)
	-- Update all tubes arround the currently placed tube
	update_next_tube(1, {x=pos.x  , y=pos.y  , z=pos.z+1})
	update_next_tube(2, {x=pos.x+1, y=pos.y  , z=pos.z  })
	update_next_tube(3, {x=pos.x  , y=pos.y  , z=pos.z-1})
	update_next_tube(4, {x=pos.x-1, y=pos.y  , z=pos.z  })
	update_next_tube(5, {x=pos.x  , y=pos.y-1, z=pos.z  })
	update_next_tube(6, {x=pos.x  , y=pos.y+1, z=pos.z  })
	-- Update the placed tube
	update_tube(pos, dir)
	return tubelib.delete_meta_data(pos, minetest.get_node(pos)) < MAX_TUBE_LENGTH
end		

	
