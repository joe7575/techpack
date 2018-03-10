--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--


local MAX_TUBE_LENGTH = 100

local TubeTypes = {
	0,0,0,0,0,0,1,3,1,3,	-- 01-10
	4,5,3,1,3,1,4,5,1,3,	-- 11-20
	1,3,4,5,3,1,3,1,4,5,	-- 21-30
	2,2,2,2,0,2,2,2,5,2,	-- 31-40
	5,0,					-- 40-41
}

local TubeFacedir = {
	0,0,0,0,0,0,0,2,0,1,	-- 01-10
	2,2,2,1,3,1,3,3,0,3,	-- 11-20
	0,0,0,0,1,1,0,1,1,1,	-- 21-30
	0,0,0,0,0,0,0,0,0,0,	-- 31-40
	0,0,					-- 40-41
}

tubelib.knownNodes = {
	["tubelib:tube1"] = true,
	["tubelib:tube2"] = true,
	["tubelib:tube3"] = true,
	["tubelib:tube4"] = true,
	["tubelib:tube5"] = true,
	["tubelib:tube6"] = true,
	["default:chest_locked"] = true,
	["default:chest"] = true,
	["default:furnace"] = true,
	["default:furnace_active"] = true,
}

-- Localize functions to avoid table lookups (better performance).
local string_find = string.find
local minetest_get_meta = minetest.get_meta
local minetest_get_node = minetest.get_node
local KnownNodes = tubelib.knownNodes
local vector_add = vector.add
local vector_equals = vector.equals

-- Translate from contact side to facedir
local SideToFacedir = {B=0, R=1, F=2, L=3, D=4, U=5}

-- 6D variant of the facedir to dir conversion 
local Facedir2Dir = {[0] = 
	{x=0,  y=0,  z=1},
	{x=1,  y=0,  z=0},
	{x=0,  y=0,  z=-1},
	{x=-1, y=0,  z=0},
	{x=0,  y=-1, z=0},
	{x=0,  y=1,  z=0},
}

-- Determine position from and facedir to the node on the other side or the tubes.
-- Param pos: my pos
-- Param npos: neighbor tube pos
local function remote_node(pos, npos)
	local dest_pos = minetest.string_to_pos(minetest.get_meta(npos):get_string("dest_pos"))
	-- two possible reasons, why dest_pos == pos:
	-- 1)  wrong side of a single tube node
	-- 2)  node connected with itself. In this case "dest_pos2" is not available
	if dest_pos and vector_equals(dest_pos, pos) then
		local dest_pos2 = minetest.string_to_pos(minetest.get_meta(npos):get_string("dest_pos2"))
		if dest_pos2 == nil then
			local facedir = minetest.get_meta(npos):get_int("facedir")
			return pos, facedir						-- node connected with itself
		else
			local facedir2 = minetest.get_meta(npos):get_int("facedir2")
			return dest_pos2, facedir2  			-- one tube connection
		end
	else
		local facedir = minetest.get_meta(npos):get_int("facedir")
		return dest_pos, facedir					-- multi tube connection
	end
end


-- Calculate the facedir to the other node, based on both node positions
local function dir_to_facedir(my_pos, other_pos)
	if my_pos.z ~= other_pos.z then return my_pos.z - other_pos.z + 1 end
	if my_pos.x ~= other_pos.x then return my_pos.x - other_pos.x + 2 end
	if my_pos.y > other_pos.y then return 5 else return 4 end
end

-------------------------------------------------------------------------------
-- API functions
-------------------------------------------------------------------------------

-- Determine neighbor position and own facedir to the node.
-- based on own pos and contact side 'B' - 'U'.
-- Function considers also tube connections.
function tubelib.get_neighbor_pos(pos, side)
	local facedir = SideToFacedir[side]
	if facedir < 4 then
		local node = minetest_get_node(pos)
		facedir = (facedir + node.param2) % 4
	end
	local npos = vector_add(pos, Facedir2Dir[facedir])
	local node = minetest_get_node(npos)
	if node and string_find(node.name, "tubelib:tube") then
		npos, facedir = remote_node(pos, npos)
	end
	return npos, facedir
end

-- use Voxel Manipulator to read the node
function tubelib.read_node_with_vm(pos)
	local vm = VoxelManip()
	local MinEdge, MaxEdge = vm:read_from_map(pos, pos)
	local data = vm:get_data()
	local param2_data = vm:get_param2_data()
	local area = VoxelArea:new({MinEdge = MinEdge, MaxEdge = MaxEdge})
	return {
		name=minetest.get_name_from_content_id(data[area:index(pos.x, pos.y, pos.z)]),
		param2 = param2_data[area:index(pos.x, pos.y, pos.z)]
	}
end

local read_node_with_vm = tubelib.read_node_with_vm

-------------------------------------------------------------------------------
-- Tube placement
-------------------------------------------------------------------------------


-- Return neighbor tubes orientation relative to the given pos.
local function get_neighbor_tubes_orientation(pos)
	local orientation = 0
	local Nodes = {
		minetest.get_node({x=pos.x  , y=pos.y  , z=pos.z+1}),
		minetest.get_node({x=pos.x+1, y=pos.y  , z=pos.z  }),
		minetest.get_node({x=pos.x  , y=pos.y  , z=pos.z-1}),
		minetest.get_node({x=pos.x-1, y=pos.y  , z=pos.z  }),
		minetest.get_node({x=pos.x  , y=pos.y-1, z=pos.z  }),
		minetest.get_node({x=pos.x  , y=pos.y+1, z=pos.z  }),
	}
	for side,node in ipairs(Nodes) do
		if KnownNodes[node.name] then  -- registered node?
			orientation = orientation * 6 + side
			if orientation > 6 then 
				break
			end
		end
	end
	return orientation
end	

local function determine_tube_node(pos)
	local node = minetest.get_node(pos) 
	if not string.find(node.name, "tubelib:tube") then
		return nil
	end
	local orientation = get_neighbor_tubes_orientation(pos)
	if orientation > 6 then 
		node.name = "tubelib:tube"..TubeTypes[orientation]
		node.param2 = TubeFacedir[orientation]
		return node
	elseif orientation > 0 then 
		orientation = orientation * 6 + (((node.param2 + 2) % 4) + 1)
		node.name = "tubelib:tube"..TubeTypes[orientation]
		node.param2 = TubeFacedir[orientation]
		return node
	end
	return nil
end	

	
local function update_tube(pos)
	local node = determine_tube_node(pos)
	if node then
		minetest.swap_node(pos, node)
	end
end		

local OffsTable = {
	{2,0},		-- tube1
	{4,5},		-- tube2
	{2,3},		-- tube3
	{2,4},		-- tube4
	{2,5},		-- tube5
}


-- The tube on 'pos1' has two ends and thus two neighbor position. 
-- One is the given 'pos', the other position is returned.
-- Param mpos: my node position
-- Param opos: the other tube position
-- Param node: the tube node
local function nodetype_to_pos(mpos, opos, node)
	local idx = string.byte(node.name, -1) - 48
	local facedir1 = OffsTable[idx][1]
	local facedir2 = OffsTable[idx][2]
	if facedir1 < 4 then
		facedir1 = (facedir1 + node.param2) % 4
	end
	if facedir2 < 4 then
		facedir2 = (facedir2 + node.param2) % 4
	end
	local dir1 = Facedir2Dir[facedir1]
	local dir2 = Facedir2Dir[facedir2]
	local p1 = vector.add(opos, dir1)
	local p2 = vector.add(opos, dir2)

	if mpos == nil then
		return p1, p2
	elseif vector.equals(p1, mpos) then
		return p2
	else
		return p1
	end
end


-- Walk to the other end of the tube line, starting at 'pos1'.
-- Returns: cnt - number of tube nodes
--          pos - the peer tube node
--          pos1 - the destination position, connected with 'pos'
local function walk_to_peer(pos, pos1)
	local node = minetest.get_node(pos1)
	local pos2
	local cnt = 0
	while string.find(node.name, "tubelib:tube") and cnt < MAX_TUBE_LENGTH do
		pos2 = nodetype_to_pos(pos, pos1, node)
		pos, pos1 = pos1, pos2
		cnt = cnt + 1
		node = minetest.get_node_or_nil(pos1) or read_node_with_vm(pos1)
	end
	return cnt, pos, pos1
end	

-- Update head tubes with peer pos and facedir of the other end
-- Needed for StackItem exchange.
local function update_head_tubes(pos)
	local node = minetest.get_node(pos)
	if string.find(node.name, "tubelib:tube") then
		local pos1, pos2 = nodetype_to_pos(nil, pos, node)
		local cnt1, peer1, dest1 = walk_to_peer(pos, pos1)
		local cnt2, peer2, dest2 = walk_to_peer(pos, pos2)
		
		if cnt1 == 0 and cnt2 == 0 then	-- first tube node placed?
			-- we have to store both dest positions
			minetest.get_meta(peer1):set_string("dest_pos", minetest.pos_to_string(dest1))
			minetest.get_meta(peer1):set_int("facedir", dir_to_facedir(peer1, dest1))
			minetest.get_meta(peer1):set_string("dest_pos2", minetest.pos_to_string(dest2))
			minetest.get_meta(peer1):set_int("facedir2", dir_to_facedir(peer2, dest2))
		else
			minetest.get_meta(peer1):set_string("dest_pos", minetest.pos_to_string(dest2))
			minetest.get_meta(peer1):set_int("facedir", dir_to_facedir(peer2, dest2))
			minetest.get_meta(peer2):set_string("dest_pos", minetest.pos_to_string(dest1))
			minetest.get_meta(peer2):set_int("facedir", dir_to_facedir(peer1, dest1))
		end
		
		-- delete meta data from old head nodes
		if cnt1 > 1 then
			minetest.get_meta(pos1):from_table(nil)
		end
		if cnt2 > 1 then
			minetest.get_meta(pos2):from_table(nil)
		end
		return cnt1 + cnt2
	end
	return 0
end	
		
-- Update all tubes arround the currently placed tube		
local function update_surrounding_tubes(pos)
	update_tube({x=pos.x  , y=pos.y  , z=pos.z+1})
	update_tube({x=pos.x+1, y=pos.y  , z=pos.z  })
	update_tube({x=pos.x  , y=pos.y  , z=pos.z-1})
	update_tube({x=pos.x-1, y=pos.y  , z=pos.z  })
	update_tube({x=pos.x  , y=pos.y-1, z=pos.z  })
	update_tube({x=pos.x  , y=pos.y+1, z=pos.z  })
	update_tube(pos)
	return update_head_tubes(pos) < MAX_TUBE_LENGTH
end		

	
-- Update tubes after a tube node is removed	
local function after_tube_removed(pos, node)
	local pos1, pos2 = nodetype_to_pos(nil, pos, node)
	update_head_tubes(pos1)
	update_head_tubes(pos2)
end

-- API function, called from all nodes, which shall be connected to tubes	
function tubelib.update_tubes(pos)
	update_tube(      {x=pos.x  , y=pos.y  , z=pos.z+1})
	update_head_tubes({x=pos.x  , y=pos.y  , z=pos.z+1})
	update_tube(      {x=pos.x+1, y=pos.y  , z=pos.z  })
	update_head_tubes({x=pos.x+1, y=pos.y  , z=pos.z  })
	update_tube(      {x=pos.x  , y=pos.y  , z=pos.z-1})
	update_head_tubes({x=pos.x  , y=pos.y  , z=pos.z-1})
	update_tube(      {x=pos.x-1, y=pos.y  , z=pos.z  })
	update_head_tubes({x=pos.x-1, y=pos.y  , z=pos.z  })
	update_tube(      {x=pos.x  , y=pos.y-1, z=pos.z  })
	update_head_tubes({x=pos.x  , y=pos.y-1, z=pos.z  })
	update_tube(      {x=pos.x  , y=pos.y+1, z=pos.z  })
	update_head_tubes({x=pos.x  , y=pos.y+1, z=pos.z  })
end		
	
local DefNodeboxes = {
    -- x1   y1    z1     x2   y2   z2
    { -1/4, -1/4, -1/4,  1/4, 1/4, 1/4 },
    { -1/4, -1/4, -1/4,  1/4, 1/4, 1/4 },
}

local DirCorrections = {
    {3, 6}, {2, 5},             -- standard tubes
    {3, 1}, {3, 2}, {3, 5},   	-- knees from front to..
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
    node_box_data = table.copy(DefNodeboxes)
    node_box_data[1][pos[1]] = node_box_data[1][pos[1]] * 2
    node_box_data[2][pos[2]] = node_box_data[2][pos[2]] * 2

	tiles_data = TilesData[idx]
	
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
			if update_surrounding_tubes(pos) == false then
				after_tube_removed(pos, minetest.get_node(pos))
				minetest.remove_node(pos)
				return itemstack
			end
		end,
		
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			after_tube_removed(pos, oldnode)
		end,
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
		{"default:steel_ingot", "",    "group:wood"},
		{"",           "group:wood",   ""},
		{"group:wood", "",             "default:tin_ingot"},
	},
})
