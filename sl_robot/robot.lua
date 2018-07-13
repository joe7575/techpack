--[[

	sl_robot
	========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	robot.lua:

]]--

local Face2Dir = {[0]=
	{x=0,  y=0,  z=1},
	{x=1,  y=0,  z=0},
	{x=0,  y=0, z=-1},
	{x=-1, y=0,  z=0},
	{x=0,  y=-1, z=0},
	{x=0,  y=1,  z=0}
}

function sl_robot.new_pos(pos, param2, step)
	return vector.add(pos, vector.multiply(Face2Dir[param2], step))
end

-- use Voxel Manipulator to read the node
local function read_node_with_vm(pos)
	local vm = VoxelManip()
	local MinEdge, MaxEdge = vm:read_from_map(pos, pos)
	local data = vm:get_data()
	local area = VoxelArea:new({MinEdge = MinEdge, MaxEdge = MaxEdge})
	return {
		name = minetest.get_name_from_content_id(data[area:index(pos.x, pos.y, pos.z)])
	}
end

-- check is posA == air-like and posB == solid and no player around
local function check_pos(posA, posB)
	local nodeA = minetest.get_node_or_nil(posA) or read_node_with_vm(posA)
	local nodeB = minetest.get_node_or_nil(posB) or read_node_with_vm(posB)
	if not minetest.registered_nodes[nodeA.name].walkable and 
			minetest.registered_nodes[nodeB.name].walkable then
		local objects = minetest.get_objects_inside_radius(posA, 1)
		if #objects ~= 0 then
			minetest.sound_play('sl_robot_go_away', {pos = posA})
			return false
		else
			return true
		end
	end
	return false
end

function sl_robot.place_robot(pos1, pos2, param2, player_name)	
	if check_pos(pos1, pos2) then
		minetest.set_node(pos1, {name = "sl_robot:robot", param2 = param2})
	end
end

function sl_robot.remove_robot(pos)	
	local node = minetest.get_node(pos)
	if node.name == "sl_robot:robot" then
		minetest.remove_node(pos)
		local pos1 = {x=pos.x, y=pos.y-1, z=pos.z}
		node = minetest.get_node(pos1)
		if node.name == "sl_robot:robot_foot" or node.name == "sl_robot:robot_leg" then
			minetest.remove_node(pos1)
			pos1 = {x=pos.x, y=pos.y-2, z=pos.z}
			node = minetest.get_node(pos1)
			if node.name == "sl_robot:robot_foot" then
				minetest.remove_node(pos1)
			end
		end
	end
end

-- Positions to check:
--     3
--  [R]1  
--   4 2
--   5 
function sl_robot.move_robot(pos, param2, step)
	local pos1 = sl_robot.new_pos(pos, param2, step)
	local pos2 = {x=pos1.x, y=pos1.y-1, z=pos1.z}
	local pos3 = {x=pos1.x, y=pos1.y+1, z=pos1.z}
	local pos4 = {x=pos.x, y=pos.y-1, z=pos.z}
	local pos5 = {x=pos.x, y=pos.y-2, z=pos.z}
	local new_pos = nil
	
	if check_pos(pos1, pos2) then  -- one step forward
		new_pos = pos1
	elseif check_pos(pos3, pos1) then  -- one step up
		new_pos = {x=pos.x, y=pos.y+1, z=pos.z}
		minetest.swap_node(pos, {name="sl_robot:robot_foot"})
		minetest.set_node(new_pos, {name="sl_robot:robot", param2=param2})
		minetest.sound_play('sl_robot_step', {pos = new_pos})
		return new_pos
	elseif check_pos(pos1, pos4) then  -- one step forward
		new_pos = pos1		
	elseif check_pos(pos4, pos5) then  -- one step down
		new_pos = pos4		
	else
		return nil -- blocked
	end
	local node4 = minetest.get_node(pos4)
	if node4.name == "sl_robot:robot_foot" or node4.name == "sl_robot:robot_leg" then
		minetest.remove_node(pos4)
		local node5 = minetest.get_node(pos5)
		if node5.name == "sl_robot:robot_foot" then
			minetest.remove_node(pos5)
		end
	end
	minetest.remove_node(pos)
	minetest.set_node(new_pos, {name="sl_robot:robot", param2=param2})
	minetest.sound_play('sl_robot_step', {pos = new_pos})
	return new_pos
end	
	
function sl_robot.turn_robot(pos, param2, dir)
	if dir == "R" then
		param2 = (param2 + 1) % 4
	else
		param2 = (param2 + 3) % 4
	end
	minetest.swap_node(pos, {name="sl_robot:robot", param2=param2})
	minetest.sound_play('sl_robot_step', {pos = pos, gain = 0.6})
	return param2
end	

-- Positions to check:
--   1
--  [R]  
--   2
function sl_robot.robot_up(pos, param2)
	local pos1 = {x=pos.x, y=pos.y+1, z=pos.z}
	local pos2 = {x=pos.x, y=pos.y-1, z=pos.z}
	if check_pos(pos1, pos2) then
		local node = minetest.get_node(pos2)
		if node.name == "sl_robot:robot_foot" then 
			minetest.swap_node(pos, {name="sl_robot:robot_leg"})
		else
			minetest.swap_node(pos, {name="sl_robot:robot_foot"})
		end
		minetest.set_node(pos1, {name="sl_robot:robot", param2=param2})
		minetest.sound_play('sl_robot_step', {pos = pos1})
		return pos1
	end
	return nil
end	

-- Positions to check:
--  [R]  
--   1
--   2
--   3
function sl_robot.robot_down(pos, param2)
	local pos1 = {x=pos.x, y=pos.y-1, z=pos.z}
	local pos2 = {x=pos.x, y=pos.y-2, z=pos.z}
	local pos3 = {x=pos.x, y=pos.y-3, z=pos.z}
	local node1 = minetest.get_node_or_nil(pos1) or read_node_with_vm(pos1)
	if node1.name == "air" and check_pos(pos2, pos3) then
		minetest.remove_node(pos)
		minetest.set_node(pos2, {name="sl_robot:robot", param2=param2})
		minetest.sound_play('sl_robot_step', {pos = pos2})
		return pos2
	end
	return nil
end	


minetest.register_node("sl_robot:robot", {
	description = "SaferLua Robot",
	-- up, down, right, left, back, front
	tiles = {
		"sl_robot_robot_top.png",
		"sl_robot_robot_bottom.png",
		"sl_robot_robot_right.png",
		"sl_robot_robot_left.png",
		"sl_robot_robot_front.png",
		"sl_robot_robot_back.png",
		
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -5/16,  3/16, -5/16,   5/16,  8/16, 5/16},
			{ -3/16,  2/16, -3/16,   3/16,  3/16, 3/16},
			{ -6/16, -7/16, -6/16,   6/16,  2/16, 6/16},
			{ -6/16, -8/16, -3/16,   6/16, -7/16, 3/16},
		},
	},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {crumbly=0, not_in_creative_inventory = 1},
	sounds = default.node_sound_metal_defaults(),
})

---- dummy robots are used as marker for stucked robots in unloaded areas
--minetest.register_node("sl_robot:robot_dummy", {
--	description = "SaferLua Robot",
--	-- up, down, right, left, back, front
--	tiles = {
--		"sl_robot_robot_top.png^[opacity:127",
--		"sl_robot_robot_bottom.png^[opacity:127",
--		"sl_robot_robot_right.png^[opacity:127",
--		"sl_robot_robot_left.png^[opacity:127",
--		"sl_robot_robot_front.png^[opacity:127",
--		"sl_robot_robot_back.png^[opacity:127",
--	},
--	drawtype = "nodebox",
--	use_texture_alpha = true,
--	node_box = {
--		type = "fixed",
--		fixed = {
--			{ -5/16,  3/16, -5/16,   5/16,  8/16, 5/16},
--			{ -3/16,  2/16, -3/16,   3/16,  3/16, 3/16},
--			{ -6/16, -7/16, -6/16,   6/16,  2/16, 6/16},
--			{ -6/16, -8/16, -3/16,   6/16, -7/16, 3/16},
--		},
--	},
--	paramtype2 = "facedir",
--	is_ground_content = false,
--	walkable = false,
--	drop = "",
--	groups = {cracky = 3},
--	sounds = default.node_sound_metal_defaults(),
--})

minetest.register_node("sl_robot:robot_leg", {
	description = "SaferLua Robot",
	tiles = {"sl_robot_robot.png^[transformR90]"},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -1/8, -4/8, -1/8,   1/8, 4/8, 1/8},
		},
	},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {crumbly=0, not_in_creative_inventory = 1},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("sl_robot:robot_foot", {
	description = "SaferLua Robot",
	tiles = {"sl_robot_robot.png^[transformR90]"},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -1/8, -4/8, -1/8,   1/8, 4/8, 1/8},
			{ -2/8, -4/8, -2/8,   2/8, -3/8, 2/8},
		},
	},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {crumbly=0, not_in_creative_inventory = 1},
	sounds = default.node_sound_metal_defaults(),
})


--minetest.register_lbm({
--	label = "[sl_robot] Remove Robots",
--	name = "sl_robot:update",
--	nodenames = {"sl_robot:robot", "sl_robot:robot_leg", "sl_robot:robot_foot"},
--	run_at_every_load = true,
--	action = function(pos, node)
--		if node.name == "sl_robot:robot" then
--			minetest.swap_node(pos, {name="sl_robot:robot_dummy", param2 = node.param2})
--		else
--			minetest.remove_node(pos)
--		end
--	end
--})

