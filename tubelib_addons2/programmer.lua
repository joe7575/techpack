--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	programmer.lua:
	
]]--

-- Load support for I18n
local S = tubelib_addons2.S

local function join_to_string(tbl)
	local t = {}
	for key,_ in pairs(tbl) do
		t[#t + 1] = key .. " "
	end
	-- remove the last blank
	return string.sub(table.concat(t), 1, -2)
end

local function reset_programmer(itemstack, user, pointed_thing)
	user:set_attribute("tubelib_prog_numbers", nil)
	minetest.chat_send_player(user:get_player_name(), S("[Tubelib Programmer] programmer reset"))
	return itemstack
end	

local function read_number(itemstack, user, pointed_thing)
	local pos = pointed_thing.under
	if pos then
		local number = tubelib.get_node_number(pos)
		if number then
			local numbers = minetest.deserialize(user:get_attribute("tubelib_prog_numbers")) or {}
			numbers[number] = true
			user:set_attribute("tubelib_prog_numbers", minetest.serialize(numbers))
			minetest.chat_send_player(user:get_player_name(), S("[Tubelib Programmer] number").." "..number.." "..S("read"))
		else
			minetest.chat_send_player(user:get_player_name(), S("[Tubelib Programmer] Unknown node on").." "..minetest.pos_to_string(pos))
		end
	else
		return reset_programmer(itemstack, user, pointed_thing)
	end
	return itemstack
end

local function program_numbers(itemstack, placer, pointed_thing)
	local pos = pointed_thing.under
	if pos then
		local meta = minetest.get_meta(pos)
		local node_number = tubelib.get_node_number(pos)
		local numbers = minetest.deserialize(placer:get_attribute("tubelib_prog_numbers")) or {}
		placer:set_attribute("tubelib_prog_numbers", nil)
		local text = join_to_string(numbers)
		local player_name = placer:get_player_name()
		if meta and meta:get_string("owner") ~= player_name then
			minetest.chat_send_player(player_name, S("[Tubelib Programmer] foreign or unknown node!"))
			return itemstack
		end
		local res = tubelib.send_request(node_number, "set_numbers", text)
		if res == true then
			minetest.chat_send_player(player_name, S("[Tubelib Programmer] node programmed!"))
		else
			minetest.chat_send_player(player_name, S("[Tubelib Programmer] Error: programmer not supported!"))
		end
		return itemstack
	else
		return reset_programmer(itemstack, placer, pointed_thing)
	end
end

minetest.register_craftitem("tubelib_addons2:programmer", {
	description = S("Tubelib Programmer"),
	inventory_image = "tubelib_addons2_programmer.png",
	stack_max = 1,
	wield_image = "tubelib_addons2_programmer_wield.png",
	groups = {cracky=1, book=1},
	-- left mouse button = program
	on_use = program_numbers,
	on_secondary_use = reset_programmer,
	-- right mouse button = read
	on_place = read_number,
})

minetest.register_craft({
	output = "tubelib_addons2:programmer",
	recipe = {
		{"", "default:steel_ingot", ""},
		{"", "tubelib:wlanchip",    ""},
		{"", "dye:red",             ""},
	},
})
