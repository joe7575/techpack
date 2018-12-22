--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	forceload.lua:
	
]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

local function in_list(list, x)
	for _,v in ipairs(list) do
		if vector.equals(v, x) then return true end
	end
	return false
end

local function remove_list_elem(list, x)
	local n = nil
	for idx, v in ipairs(list) do
		if vector.equals(v, x) then 
			n = idx
			break
		end
	end
	if n then
		table.remove(list, n)
	end
	print(dump(list))
	return list
end

local function chat(player, text)
	minetest.chat_send_player(player:get_player_name(), "[Tubelib] "..text)
end

local function calc_area(pos)
	local xpos = (math.floor(pos.x / 16) * 16)
	local ypos = (math.floor(pos.y / 16) * 16)
	local zpos = (math.floor(pos.z / 16) * 16)
	local pos1 = {x=xpos, y=ypos, z=zpos}
	local pos2 = {x=xpos+15, y=ypos+15, z=zpos+15}
	return pos1, pos2
end

local function add_pos(pos, player)
	local lPos = minetest.deserialize(player:get_attribute("tubelib_forceload_blocks")) or {}
	if not in_list(lPos, pos) and #lPos < tubelib.max_num_forceload_blocks then
		lPos[#lPos+1] = pos
		player:set_attribute("tubelib_forceload_blocks", minetest.serialize(lPos))
		return true
	end
	return false
end
	
local function del_pos(pos, player)
	local lPos = minetest.deserialize(player:get_attribute("tubelib_forceload_blocks")) or {}
	lPos = remove_list_elem(lPos, pos)
	lPos = remove_list_elem(lPos, pos)
	player:set_attribute("tubelib_forceload_blocks", minetest.serialize(lPos))
end

local function get_pos_list(player)
	return minetest.deserialize(player:get_attribute("tubelib_forceload_blocks")) or {}
end

local function get_data(pos, player)
	local pos1, pos2 = calc_area(pos)
	local num = #minetest.deserialize(player:get_attribute("tubelib_forceload_blocks")) or 0
	local max = tubelib.max_num_forceload_blocks
	return pos1, pos2, num, max
end

minetest.register_node("tubelib:forceload", {
	description = "Tubelib Forceload Block",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		{
			image = "tubelib_forceload.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 0.5,
			},
		},
	},

	after_place_node = function(pos, placer, itemstack)
		if add_pos(pos, placer) then
			minetest.forceload_block(pos, true)
			local pos1, pos2, num, max = get_data(pos, placer)
			M(pos):set_string("infotext", "Area "..S(pos1).." to "..S(pos2).." loaded!")
			chat(placer, "Area ("..num.."/"..max..") "..S(pos1).." to "..S(pos2).." loaded!")
		else
			chat(placer, "Max. number of Forceload Blocks reached!")
			minetest.remove_node(pos)
			return itemstack
		end
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		del_pos(pos, digger)
		minetest.forceload_free_block(pos, true)
	end,

	paramtype = "light",
	sunlight_propagates = true,
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})



minetest.register_craft({
	output = "tubelib:forceload",
	recipe = {
		{"group:wood", "", "group:wood"},
		{"", "basic_materials:energy_crystal_simple", ""},
		{"group:wood", "", "group:wood"},
	},
})


minetest.register_on_joinplayer(function(player)
	for _,pos in ipairs(get_pos_list(player)) do
		minetest.forceload_block(pos, true)
	end
end)

minetest.register_on_leaveplayer(function(player)
	for _,pos in ipairs(get_pos_list(player)) do
		minetest.forceload_free_block(pos, true)
	end
end)
