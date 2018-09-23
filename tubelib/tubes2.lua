--[[

	Tube Library
	============

	Copyright (C) 2017-2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua
	
	tubes2.lua: Node registration and API function to move items via tubes

]]--

-- Convertion of contact side to facedir
local SideToFacedir = {B=0, R=1, F=2, L=3, D=4, U=5}

-- Calculate the facedir to the other node, based on both node positions
local function dir_to_facedir(my_pos, other_pos)
	if my_pos.z ~= other_pos.z then return my_pos.z - other_pos.z + 1 end
	if my_pos.x ~= other_pos.x then return my_pos.x - other_pos.x + 2 end
	if my_pos.y > other_pos.y then return 5 else return 4 end
end

local function remote_node(pos, dir)
	local meta = minetest.get_meta(pos)
	local cnt
	
	-- legacy tube?
	if meta:get_string("dest_pos2") ~= "" then
		meta:from_table(nil)
	end
	
	-- data available
	local dest_pos = meta:get_string("dest_pos")
	if dest_pos ~= "" then
		local npos = minetest.string_to_pos(dest_pos)
		local facedir =  meta:get_int("facedir")
		return npos, facedir+1
	end	
		
	-- determine data and store as meta
	cnt, pos, dir = tubelib.walk_to_peer(pos, dir)
	local pos1,_  = tubelib.get_next_tube(pos, dir)
	meta:set_string("dest_pos", minetest.pos_to_string(pos1))
	meta:set_int("facedir", dir - 1)

	return pos1, dir
end	
	
local function is_known_node(pointed_thing)
	if pointed_thing.type == "node" then
		local node = minetest.get_node(pointed_thing.under)
		if tubelib.KnownNodes[node.name] then
			return pointed_thing.under
		end
	end
	return nil
end

-- Determine neighbor position and own facedir to the node.
-- based on own pos and contact side 'B' - 'U'.
-- Function considers also tube connections.
function tubelib.get_neighbor_pos(pos, side)
	local facedir = SideToFacedir[side]
	local dir
	if facedir < 4 then
		local node = minetest.get_node(pos)
		dir = ((facedir + node.param2) % 4) + 1
	end
	local npos, ndir = tubelib.get_next_tube(pos, dir)
	local node = minetest.get_node(npos)
	if tubelib.TubeNames[node.name] then
		if ndir then
			npos, ndir = remote_node(npos, ndir)
		end
		return npos, ndir-1
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
			local dir1 = nil
			local dir2 = nil
			local pitch = placer:get_look_pitch()
			local known_pos = is_known_node(pointed_thing)
			local straight_ahead = placer:get_player_control().sneak and not known_pos
			if known_pos then -- placer pointed to a known node (chest)
				dir2 = dir_to_facedir(pos, known_pos) + 1
			end
			if pitch > 1 then -- up?
				dir1 = 6
			elseif pitch < -1 then -- down?
				dir1 = 5
			else
				dir1 = minetest.dir_to_facedir(placer:get_look_dir()) + 1
			end
			if not tubelib.update_tubes(pos, dir1, dir2, straight_ahead) then
				tubelib.delete_meta_data(pos, minetest.get_node(pos))
				minetest.remove_node(pos)
				return itemstack
			end
		end,
		
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			tubelib.delete_meta_data(pos, oldnode)
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
