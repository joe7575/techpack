--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua
	
	Funtions for tube placement/alignment

]]--

--[[
	
Tubes 1..5 can be placed according to 'param2'.
The two openings point in the directions 'dir',
(N=1, E=2, S=3, W=4, D=5, U=6) 
which corresponds to the following tube alignments:

tube No | param2 | dir | alignment 
--------+--------+-----+-------------
	1   |   0    | N/S | 1*6 + 3 = 9 
	1   |   1    | E/W | 2*6 + 4 = 16
	2   |   0    | D/U | 5*6 + 6 = 36
	3   |   0    | S/W | 3*6 + 4 = 22 
	3   |   1    | N/W | 1*6 + 4 = 10
	3   |   2    | N/E | 1*6 + 2 = 8
	3   |   3    | E/S | 2*6 + 3 = 15
	4   |   0    | S/D | 3*6 + 5 = 23
	4   |   1    | W/D | 4*6 + 5 = 29
	4   |   2    | N/D | 1*6 + 5 = 11
	4   |   3    | E/D | 2*6 + 5 = 17
	5   |   0    | S/U | 3*6 + 6 = 24
	5   |   1    | W/U | 4*6 + 6 = 30
	5   |   2    | N/U | 1*6 + 6 = 12
	5   |   3    | E/U | 2*6 + 6 = 18

]]--

-- debugging 
local P = minetest.pos_to_string

local MAX_TUBE_LENGTH = 100

-- Conversion from tube alignment to tube number
local TubeTypes = {
	0,0,0,0,0, 0,0,3,1,3,    -- 01-10
	4,5,3,1,3, 1,4,5,1,3,    -- 11-20
	1,3,4,5,3, 1,3,1,4,5,    -- 21-30
	2,2,2,2,0, 2,2,2,5,2,    -- 31-40
	5,0,                     -- 41-42
}

-- Conversion from tube alignment to param2
local TubeParam2 = {
	0,0,0,0,0, 0,0,2,0,1,    -- 01-10
	2,2,2,1,3, 1,3,3,0,3,    -- 11-20
	0,0,0,0,1, 1,0,1,1,1,    -- 21-30
	0,0,0,0,0, 0,0,0,0,0,    -- 31-40
	0,0,                     -- 41-42
}


-- Conversion from  tube number/param2 to tube hole dirs (view from the outside)
local TubeHoles = {
	[10] = {1,3},
	[12] = {1,3},
	[11] = {2,4},
	[13] = {2,4},
	[20] = {5,6},
	[30] = {1,2},
	[31] = {3,2},
	[32] = {3,4},
	[33] = {1,4},
	[40] = {1,6},
	[41] = {2,6},
	[42] = {3,6},
	[43] = {4,6},
	[50] = {1,5},
	[51] = {2,5},
	[52] = {3,5},
	[53] = {4,5},
}

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

local TubeNames = {
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

-- Convertion of contact side to facedir
local SideToFacedir = {B=0, R=1, F=2, L=3, D=4, U=5}


-------------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------------

local function in_list(list, x)
	for _, v in ipairs(list) do
		if v == x then return true end
	end
	return false
end

-- convert 6D-dir to position
local function dir_to_pos(pos, dir)
	return vector.add(pos, Dir2Offset[dir])
end

-- return all 6 relevant surrounding positions
local function get_6Pos(pos)
	return {
		{x=pos.x  , y=pos.y  , z=pos.z+1},
		{x=pos.x+1, y=pos.y  , z=pos.z  },
		{x=pos.x  , y=pos.y  , z=pos.z-1},
		{x=pos.x-1, y=pos.y  , z=pos.z  },
		{x=pos.x  , y=pos.y-1, z=pos.z  },
		{x=pos.x  , y=pos.y+1, z=pos.z  },
	}
end

-- Calculate the facedir to the other node, based on both node positions
local function dir_to_facedir(my_pos, other_pos)
	if my_pos.z ~= other_pos.z then return my_pos.z - other_pos.z + 1 end
	if my_pos.x ~= other_pos.x then return my_pos.x - other_pos.x + 2 end
	if my_pos.y > other_pos.y then return 5 else return 4 end
end

-- The 'oldnode' on 'pos' had two ends and thus two neighbor position. 
local function nodetype_to_pos(pos, node)
	local key = (string.byte(node.name, -1) - 48) * 10 + node.param2
	local pos1 = dir_to_pos(pos, Turn180Deg[TubeHoles[key][1]])
	local pos2 = dir_to_pos(pos, Turn180Deg[TubeHoles[key][2]])
	return pos1, pos2
end

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

-- Walk to the other end of the tube line, starting at 'pos1'.
-- Returns: cnt - number of tube nodes
--          pos - the peer tube node
--          pos1 - the drop position, next after 'pos'
local function walk_to_peer(pos, pos1)
	local node = minetest.get_node(pos1)
	local cnt = 0
	while TubeNames[node.name] and cnt < MAX_TUBE_LENGTH do
		local new_pos1, new_pos2 = nodetype_to_pos(pos1, node)
		if vector.equals(new_pos1, pos) then
			pos = pos1
			pos1 = new_pos2
		elseif vector.equals(new_pos2, pos) then
			pos = pos1
			pos1 = new_pos1
		end
		cnt = cnt + 1
		node = minetest.get_node_or_nil(pos1) or tubelib.read_node_with_vm(pos1)
	end
	return cnt, pos, pos1
end	
	
-- Delete meta data of the peer node
local function delete_meta_data(pos, node)
	local pos1, pos2 = nodetype_to_pos(pos, node)
	if pos1 then
		local cnt, pos, pos1 = walk_to_peer(pos, pos1)
		-- delete meta on peer tube
		if cnt > 0 then
			minetest.get_meta(pos):from_table(nil)
		end
	end
	if pos2 then
		local cnt, pos, pos1 = walk_to_peer(pos, pos2)
		-- delete meta on peer tube
		if cnt > 0 then
			minetest.get_meta(pos):from_table(nil)
		end
	end
end


-------------------------------------------------------------------------------
-- Place a tube node
-------------------------------------------------------------------------------

-- always use the smaller number first
local function calc_alignment(dir1, dir2)
	if dir1 < dir2 then
		return dir1 * 6 + dir2
	else
		return dir2 * 6 + dir1
	end
end
	
-- Determine the tube alignment
-- based on 2 neighbor tubes, or one neighbour 
-- and node.param2
local function get_alignment(pos, lDirs, pitch)
	if #lDirs == 1 then
		if pitch > 1 then
			table.insert(lDirs, {dir = 6})
		elseif pitch < -1 then
			table.insert(lDirs, {dir = 5})
		else
			local node = minetest.get_node(pos)
			table.insert(lDirs, {dir = ((node.param2 + 2) % 4) + 1})
		end
	end
	if #lDirs >= 2 then 
		return calc_alignment(lDirs[1].dir, lDirs[2].dir)
	end
end	

-- return number of tubelib compatible nodes on the 6 surrounding positions 
-- plus their alignment
local function get_num_conn(pos)
	local num = 0
	local lDir = {}
	for dir,npos in ipairs(get_6Pos(pos)) do
		local node = minetest.get_node(npos)
		if tubelib.KnownNodes[node.name] then
			num = num + 1
			table.insert(lDir, {dir=dir, almnt=0})
		end
	end
	return num, get_alignment(pos, lDir, 0)
end

local function open_hole(dir, name, param2)
	local key = (string.byte(name, -1) - 48) * 10 + param2
	if in_list(TubeHoles[key], dir) then
		return true
	end
	return false
end	
	
-- Return all tubes with less then 3 connections
local function get_any_neighbour_tubes(pos)
	local lAttr= {}				-- used as result
	for dir,npos in ipairs(get_6Pos(pos)) do
		local node = minetest.get_node(npos)
		if TubeNames[node.name] then
			local num, almnt = get_num_conn(npos)
			if num < 3 then 
				table.insert(lAttr, {dir=dir, almnt=almnt})
			end
		elseif tubelib.KnownNodes[node.name] then
			-- chests and other nodes
			table.insert(lAttr, {dir=dir, almnt=0})
		end
	end
	return lAttr
end

-- Return all tubes with holes pointing in 'pos' direction
local function get_tubes_with_visible_holes(pos)
	local lAttr= {}				-- used as result
	for dir,npos in ipairs(get_6Pos(pos)) do
		local node = minetest.get_node(npos)
		if TubeNames[node.name] then
			if open_hole(dir, node.name, node.param2) then
				table.insert(lAttr, {dir=dir})
			end
		elseif tubelib.KnownNodes[node.name] then
			-- chests and other nodes
			table.insert(lAttr, {dir=dir, almnt=0})
		end
	end
	return lAttr
end

local function update_tube(pos, dir, almnt)
	if dir then
		pos = dir_to_pos(pos, dir)
	end
	local node = minetest.get_node(pos)
	node.name = "tubelib:tube"..TubeTypes[almnt]
	node.param2 = TubeParam2[almnt]
	minetest.swap_node(pos, node)
	delete_meta_data(pos, node)
end	

-- If tube has surrounding tubes with open ends, 
-- start the update process of the neighbour tubes and the new tube.
local function update_tubes(pos, pitch)
	local lAttr = get_tubes_with_visible_holes(pos)
	if #lAttr > 0 then
		local almnt = get_alignment(pos, lAttr, pitch)
		update_tube(pos, nil, almnt)
	else
		lAttr = get_any_neighbour_tubes(pos)
		if #lAttr == 1 then
			update_tube(pos, lAttr[1].dir, lAttr[1].almnt)
			local almnt = get_alignment(pos, lAttr, pitch)
			update_tube(pos, nil, almnt)
		end
	end
	return true
end
	
	
-------------------------------------------------------------------------------
-- Remove a tube node
-------------------------------------------------------------------------------

-- Update tubes after a tube node is removed	
local function after_tube_removed(pos, oldnode)
	local pos1, pos2 = nodetype_to_pos(pos, oldnode)
	if pos1 then
		local cnt, pos, pos1 = walk_to_peer(pos, pos1)
		-- delete meta on peer tube
		if cnt > 0 then
			minetest.get_meta(pos):from_table(nil)
		end
	end
	if pos2 then
		local cnt, pos, pos1 = walk_to_peer(pos, pos2)
		-- delete meta on peer tube
		if cnt > 0 then
			minetest.get_meta(pos):from_table(nil)
		end
	end
end


-------------------------------------------------------------------------------
-- API functions
-------------------------------------------------------------------------------

local function remote_node(pos, npos)
	local meta = minetest.get_meta(npos)
	
	-- legacy tube?
	if meta:get_string("dest_pos2") ~= "" then
		meta:from_table(nil)
	end
	
	-- data available
	local dest_pos = meta:get_string("dest_pos")
	if dest_pos ~= "" then
		local npos = minetest.string_to_pos(dest_pos)
		local facedir =  meta:get_int("facedir")
		return npos, facedir
	end	
		
	-- determine data
	_,_, npos = walk_to_peer(pos, npos)
	local facedir = dir_to_facedir(pos, npos)
	meta:set_string("dest_pos", minetest.pos_to_string(npos))
	meta:set_int("facedir", facedir)
	return npos, facedir
end	
	
-- Determine neighbor position and own facedir to the node.
-- based on own pos and contact side 'B' - 'U'.
-- Function considers also tube connections.
function tubelib.get_neighbor_pos(pos, side)
	local facedir = SideToFacedir[side]
	if facedir < 4 then
		local node = minetest.get_node(pos)
		facedir = ((facedir + node.param2) % 4)
	end
	local npos = dir_to_pos(pos, facedir+1)
	local node = minetest.get_node(npos)
	if TubeNames[node.name] then
		npos, facedir = remote_node(pos, npos)
	end
	return npos, facedir
end


-------------------------------------------------------------------------------
-- Node registration
-------------------------------------------------------------------------------

local DefNodeboxes = {
	-- x1   y1    z1     x2   y2   z2
	{ -1/4, -1/4, -1/4,  1/4, 1/4, 1/4 },
	{ -1/4, -1/4, -1/4,  1/4, 1/4, 1/4 },
}

local DirCorrections = {
	{3, 6}, {2, 5},             -- standard tubes
	{3, 1}, {3, 2}, {3, 5},     -- knees from front to..
}

local SelectBoxes = {
	{ -1/4, -1/4, -1/2,  1/4, 1/4, 1/2 },
	{ -1/4, -1/2, -1/4,  1/4, 1/2, 1/4 },
	{ -1/2, -1/4, -1/2,  1/4, 1/4, 1/4 },
	{ -1/4, -1/2, -1/2,  1/4, 1/4, 1/4 },
	{ -1/4, -1/4, -1/2,  1/4, 1/2, 1/4 },
}

local TilesData = {
    -- up, down, right, left, back, front
	{
		"tubelib_tube.png^[transformR90",
		"tubelib_tube.png^[transformR90",
		"tubelib_tube.png",
		"tubelib_tube.png",
		"tubelib_hole.png",
		"tubelib_hole.png",
	},
	{
		"tubelib_hole.png",
		"tubelib_hole.png",
		"tubelib_tube.png^[transformR90",
		"tubelib_tube.png^[transformR90",
		"tubelib_tube.png^[transformR90",
        "tubelib_tube.png^[transformR90",
	},
	{
		"tubelib_knee.png^[transformR270",
		"tubelib_knee.png^[transformR180",
		"tubelib_knee2.png^[transformR270",
		"tubelib_hole2.png^[transformR90",
		"tubelib_knee2.png^[transformR90",
		"tubelib_hole2.png^[transformR270",
	},
	{
		"tubelib_knee2.png",
		"tubelib_hole2.png^[transformR180",
		"tubelib_knee.png^[transformR270",
		"tubelib_knee.png",
		"tubelib_knee2.png",
		"tubelib_hole2.png",
	},
	{
		"tubelib_hole2.png",
		"tubelib_knee2.png^[transformR180",
		"tubelib_knee.png^[transformR180",
		"tubelib_knee.png^[transformR90",
		"tubelib_knee2.png^[transformR180",
		"tubelib_hole2.png^[transformR180",
	},
}


for idx,pos in ipairs(DirCorrections) do
	local node_box_data = table.copy(DefNodeboxes)
	node_box_data[1][pos[1]] = node_box_data[1][pos[1]] * 2
	node_box_data[2][pos[2]] = node_box_data[2][pos[2]] * 2

	local tiles_data = TilesData[idx]
	local hidden
	
	if idx == 1 then
		hidden = 0
	else
		hidden = 1
	end
	minetest.register_node("tubelib:tube"..idx, {
		description = "Tubelib Tube",
		tiles = tiles_data,
		drawtype = "nodebox",
		node_box = {
		  type = "fixed",
		  fixed = node_box_data,
		},
		selection_box = {
			type = "fixed",
			fixed = SelectBoxes[idx],
		},
		collision_box = {
			type = "fixed",
			fixed = SelectBoxes[idx],
		},
		
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			update_tubes(pos, placer:get_look_vertical())
		end,
		
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			delete_meta_data(pos, oldnode)
		end,
		
		on_rotate = screwdriver.disallow,
		paramtype2 = "facedir",
		paramtype = "light",
		sunlight_propagates = true,
		is_ground_content = false,
		groups = {choppy=2, cracky=3, stone=1, not_in_creative_inventory=hidden},
		drop = "tubelib:tube1",
		sounds = default.node_sound_wood_defaults(),
    })
end


minetest.register_craft({
	output = "tubelib:tube1 4",
	recipe = {
		{"default:steel_ingot", "",             "group:wood"},
		{"",                    "group:wood",   ""},
		{"group:wood",          "",             "default:tin_ingot"},
	},
})
