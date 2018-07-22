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


local Inventories = {
	["default:chest"] = {take = "main", add = "main", fuel = "main"},
	["default:chest_locked"] = {take = "main", add = "main", fuel = "main"},
	["default:chest_locked"] = {take = "main", add = "main", fuel = "main"},
	["default:furnace"] = {take = "dst", add = "src", fuel = "fuel"},
	["default:furnace_active"] = {take = "dst", add = "src", fuel = "fuel"},
	["tubelib:distributor"] = {take = "src", add = "src", fuel = "src"},
	["gravelsieve:sieve"] = {take = "dst", add = "src", fuel = "src"},
	["gravelsieve:auto_sieve0"] = {take = "dst", add = "src", fuel = "src"},
	["gravelsieve:auto_sieve1"] = {take = "dst", add = "src", fuel = "src"},
	["gravelsieve:auto_sieve2"] = {take = "dst", add = "src", fuel = "src"},
	["gravelsieve:auto_sieve3"] = {take = "dst", add = "src", fuel = "src"},
	["tubelib_addons1:autocrafter"] = {take = "dst", add = "src", fuel = "src"},
	["tubelib_addons1:autocrafter_active"] = {take = "dst", add = "src", fuel = "src"},
	["tubelib_addons1:chest"] = {take = "main", add = "main", fuel = "main"},
	["tubelib_addons1:fermenter"] = {take = "dst", add = "src", fuel = "src"},
	["tubelib_addons1:reformer"] = {take = "dst", add = "src", fuel = "src"},
	["tubelib_addons1:funnel"] = {take = "main", add = "main", fuel = "main"},
	["tubelib_addons1:grinder"] = {take = "dst", add = "src", fuel = "src"},
	["tubelib_addons1:grinder_active"] = {take = "dst", add = "src", fuel = "src"},
	["tubelib_addons1:harvester_base"] = {take = "main", add = "main", fuel = "fuel"},
	["tubelib_addons1:quarry"] = {take = "main", add = "main", fuel = "fuel"},
	["tubelib_addons1:quarry_active"] = {take = "main", add = "main", fuel = "fuel"},
--	[""] = {take = "", add = "", fuel = ""},
--	[""] = {take = "", add = "", fuel = ""},
--	[""] = {take = "", add = "", fuel = ""},
--	[""] = {take = "", add = "", fuel = ""},
--	[""] = {take = "", add = "", fuel = ""},
--	[""] = {take = "", add = "", fuel = ""},
--	[""] = {take = "", add = "", fuel = ""},
--	[""] = {take = "", add = "", fuel = ""},
--	[""] = {take = "", add = "", fuel = ""},
--	[""] = {take = "", add = "", fuel = ""},
}

-- return the largest stack
local function peek(src_list)
	local max_val = 0
	local slot = nil
	for idx,stack in ipairs(src_list) do
		if stack:get_count() > max_val then
			max_val = stack:get_count()
			slot = idx
		end
	end
	return slot
end
	
-- try to take the number of items from an inventory
local function take_num_items(src_list, num, dst_stack)
	local slot = peek(src_list)
	if slot then
		local taken = src_list[slot]:take_item(num)
		if dst_stack:item_fits(taken) then
			dst_stack:add_item(taken)
			return true
		end
	end
	return false
end	

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

local function fake_player(name)
	return {
		get_player_name = function() return name end,
	}
end

local function place_node(pos, owner, node_name, param2)
	local under = {x=pos.x, y=pos.y-1, z=pos.z}
	minetest.set_node(pos, {name=node_name, param2=param2})
	local pointed_thing = {type="node", under=under, above=pos}
	local itemstack = ItemStack(node_name)
	pcall(minetest.after_place_node, pos, fake_player(owner), itemstack, pointed_thing)
end

local function remove_node(pos)
	local node = minetest.get_node_or_nil(pos) or read_node_with_vm(pos)
	if minetest.registered_nodes[node.name].after_dig_node then
		return -- don't remove nodes with some intelligence
	end
	minetest.remove_node(pos)
	return ItemStack(node.name)
end


function sl_robot.place_robot(pos1, pos2, param2, player_name)	
	if check_pos(pos1, pos2) then
		minetest.set_node(pos1, {name = "sl_robot:robot", param2 = param2})
	end
end

function sl_robot.remove_robot(pos)	
	local node = minetest.get_node_or_nil(pos) or read_node_with_vm(pos)
	if node.name == "sl_robot:robot" then
		minetest.remove_node(pos)
		local pos1 = {x=pos.x, y=pos.y-1, z=pos.z}
		node = minetest.get_node_or_nil(pos1) or read_node_with_vm(pos1)
		if node.name == "sl_robot:robot_foot" or node.name == "sl_robot:robot_leg" then
			minetest.remove_node(pos1)
			pos1 = {x=pos.x, y=pos.y-2, z=pos.z}
			node = minetest.get_node_or_nil(pos1) or read_node_with_vm(pos1)
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
	local node4 = minetest.get_node_or_nil(pos4) or read_node_with_vm(pos4)
	if node4.name == "sl_robot:robot_foot" or node4.name == "sl_robot:robot_leg" then
		minetest.remove_node(pos4)
		local node5 = minetest.get_node_or_nil(pos5) or read_node_with_vm(pos5)
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
		local node = minetest.get_node_or_nil(pos2) or read_node_with_vm(pos2)
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
	if check_pos(pos1, pos2) 
	or (node1.name == "air" and check_pos(pos2, pos3))
	or (node1.name == "sl_robot:robot_leg" or node1.name == "sl_robot:robot_foot") then
		remove_node(pos)
		minetest.set_node(pos1, {name="sl_robot:robot", param2=param2})
		minetest.sound_play('sl_robot_step', {pos = pos1})
		return pos1
	end
	return nil
end	

-- take items from another inventory and put it into the own inventory slot
function sl_robot.robot_take(base_pos, robot_pos, param2, owner, num, slot)
	local pos1 = sl_robot.new_pos(robot_pos, param2, 1)
	if minetest.is_protected(pos1, owner) then
		return
	end
	local node = minetest.get_node_or_nil(pos1) or read_node_with_vm(pos1)
	if Inventories[node.name] then
		local listname = Inventories[node.name].take
		local src_inv = minetest.get_inventory({type="node", pos=pos1})
		if src_inv:is_empty(listname) then
			return
		end
		local src_list = src_inv:get_list(listname)
		local dst_inv = minetest.get_inventory({type="node", pos=base_pos})
		local dst_list = dst_inv:get_list("main")
		if take_num_items(src_list, num, dst_list[slot]) then
			src_inv:set_list(listname, src_list)
			dst_inv:set_list("main", dst_list)
		end
	end
end

function sl_robot.robot_add(base_pos, robot_pos, param2, owner, num, slot)
	local pos1 = sl_robot.new_pos(robot_pos, param2, 1)
	if minetest.is_protected(pos1, owner) then
		return
	end
	local node = minetest.get_node_or_nil(pos1) or read_node_with_vm(pos1)
	if Inventories[node.name] then
		local listname = Inventories[node.name].take
		local dst_inv = minetest.get_inventory({type="node", pos=pos1})
		local dst_list = dst_inv:get_list(listname)
		local src_inv = minetest.get_inventory({type="node", pos=base_pos})
		local src_list = src_inv:get_list("main")
		local taken = src_list[slot]:take_item(num)
		if dst_inv:room_for_item(listname, taken) then
			dst_inv:add_item(listname, taken)
			src_inv:set_list("main", src_list)
		end
	end
end

function sl_robot.robot_place(base_pos, robot_pos, param2, owner, dir, slot)
	local pos1
	if dir == "U" then
		pos1 = {x=robot_pos.x, y=robot_pos.y+1, z=robot_pos.z} 
	elseif dir == "D" then
		pos1 = {x=robot_pos.x, y=robot_pos.y-1, z=robot_pos.z} 
	else
		pos1 = sl_robot.new_pos(robot_pos, param2, 1)
	end
	if minetest.is_protected(pos1, owner) then
		return
	end
	local src_inv = minetest.get_inventory({type="node", pos=base_pos})
	local src_list = src_inv:get_list("main")
	local taken = src_list[slot]:take_item(1)
	if taken and taken:get_count() > 0 then
		local node1 = minetest.get_node_or_nil(pos1) or read_node_with_vm(pos1)
		if node1.name == "sl_robot:robot_leg" then
			local pos2 = {x=pos1.x, y=pos1.y-1, z=pos1.z}
			remove_node(pos2)  -- remove foot
		elseif node1.name == "sl_robot:robot_foot" then
			remove_node(pos1)
		elseif minetest.registered_nodes[node1.name].walkable then
			return
		end
		place_node(pos1, owner, taken:get_name(), param2)
		src_inv:set_list("main", src_list)
	end
end

function sl_robot.robot_dig(base_pos, robot_pos, param2, owner, dir, slot)
	local pos1
	if dir == "U" then
		pos1 = {x=robot_pos.x, y=robot_pos.y+1, z=robot_pos.z} 
	elseif dir == "D" then
		pos1 = {x=robot_pos.x, y=robot_pos.y-1, z=robot_pos.z} 
	else
		pos1 = sl_robot.new_pos(robot_pos, param2, 1)
	end
	if minetest.is_protected(pos1, owner) then
		return
	end
	local item = remove_node(pos1)
	if item then
		local src_inv = minetest.get_inventory({type="node", pos=base_pos})
		local src_list = src_inv:get_list("main")
		src_list[slot]:add_item(item)
		src_inv:set_list("main", src_list)
	end
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
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {crumbly=0, not_in_creative_inventory = 1},
	sounds = default.node_sound_metal_defaults(),
})

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
	paramtype = "light",
	sunlight_propagates = true,
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
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {crumbly=0, not_in_creative_inventory = 1},
	sounds = default.node_sound_metal_defaults(),
})

