--[[

	SmartLine
	=========

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	playerdetector.lua:
	
]]--

-- Load support for I18n
local S = smartline.S

local function switch_on(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	node.name = "smartline:playerdetector_active"
	minetest.swap_node(pos, node)
	local number = meta:get_string("number")
	local numbers = meta:get_string("numbers")
	local owner = meta:get_string("owner")
	tubelib.send_message(numbers, owner, nil, "on", number)
end

local function switch_off(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	node.name = "smartline:playerdetector"
	minetest.swap_node(pos, node)
	local number = meta:get_string("number")
	local numbers = meta:get_string("numbers")
	local owner = meta:get_string("owner")
	tubelib.send_message(numbers, owner, nil, "off", number)
end

local function scan_for_player(pos)
	local meta = minetest.get_meta(pos)
	local names = meta:get_string("names") or ""
	for _, object in pairs(minetest.get_objects_inside_radius(pos, 4)) do
		if object:is_player() then
			if names == "" then 
				meta:set_string("player_name", object:get_player_name())
				return true 
			end
			for _,name in ipairs(string.split(names, " ")) do
				if object:get_player_name() == name then 
					meta:set_string("player_name", name)
					return true 
				end
			end
		end
	end
	meta:set_string("player_name", nil)
	return false
end

local function formspec_help()
	local help = table.concat({
			S("Input the number(s) of the receiving node(s)."),
			S("Separate numbers via blanks, like '0123 0234'."),
			S("Input the player name(s) separated by blanks,"),
			S("or leave it blank for all players.")
		}, "\n")
	return "size[10,9]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[3,0;"..S("Player Detector Help").."]"..
		"label[0,1;"..help.."]"..
		"button_exit[4,8;2,1;exit2;"..S("close").."]"
end


local function formspec(numbers, names)
	return "size[8,5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[2,0;"..S("Player Detector").."]"..
		"field[0.3,1;8,1;numbers;"..S("Receiver node numbers:")..";"..numbers.."]" ..
		"field[0.3,2.5;8,1;names;"..S("Player name(s):")..";"..names.."]" ..
		"button_exit[5,3.5;2,1;exit1;"..S("Save").."]"..
		"button[1,3.5;1,1;help;"..S("help").."]"
end

local function on_receive_fields(pos, formname, fields, player)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	if player:get_player_name() == owner then
		print(dump(fields))
		if fields.exit1 then
			if tubelib.check_numbers(fields.numbers) then
				meta:set_string("numbers", fields.numbers)
			end
			meta:set_string("names", fields.names)
			meta:set_string("formspec", formspec(fields.numbers, fields.names))
		elseif fields.help then
			meta:set_string("formspec", formspec_help())
		elseif fields.exit2 then
			local numbers = meta:get_string("numbers")
			local names = meta:get_string("names")
			meta:set_string("formspec", formspec(numbers, names))
		end
	end
end

minetest.register_node("smartline:playerdetector", {
	description = S("SmartLine Player Detector"),
	inventory_image = "smartline_detector_inventory.png",
	tiles = {
		-- up, down, right, left, back, front
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png^smartline_detector.png",
	},

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -6/32, -6/32, 14/32,  6/32,  6/32, 16/32},
		},
	},
	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "smartline:playerdetector")
		local meta = minetest.get_meta(pos)
		meta:set_string("number", number)
		local numbers = meta:get_string("numbers") or ""
		local names = meta:get_string("names") or ""
		meta:set_string("formspec", formspec(numbers, names))
		meta:set_string("infotext", S("SmartLine Player Detector").." "..number)
		meta:set_string("owner", placer:get_player_name())
		minetest.get_node_timer(pos):start(1)
	end,

	on_receive_fields = on_receive_fields,
	
	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,
	
	on_timer = function (pos, elapsed)
		if tubelib.data_not_corrupted(pos) then
			if scan_for_player(pos) then
				switch_on(pos)
				minetest.get_node_timer(pos):start(1)
				return false
			end
			return true
		end
		return false
	end,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("smartline:playerdetector_active", {
	description = S("SmartLine Player Detector"),
	tiles = {
		-- up, down, right, left, back, front
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png^smartline_detector_active.png",
	},

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -6/32, -6/32, 14/32,  6/32,  6/32, 16/32},
		},
	},
	
	on_receive_fields = on_receive_fields,
	
	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,

	on_timer = function (pos, elapsed)
		if not scan_for_player(pos) then
			switch_off(pos)
			minetest.get_node_timer(pos):start(1)
			return false
		end
		return true
	end,
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
	drop = "smartline:playerdetector"
})

minetest.register_craft({
	output = "smartline:playerdetector",
	recipe = {
		{"", "default:copper_ingot", ""},
		{"dye:blue", "default:copper_ingot", "tubelib:wlanchip"},
		{"", "", ""},
	},
})

tubelib.register_node("smartline:playerdetector", {"smartline:playerdetector_active"}, {
	on_recv_message = function(pos, topic, payload)
		if topic == "set_numbers" then
			local meta = minetest.get_meta(pos)
			meta:set_string("numbers", payload)
			local names = meta:get_string("names") or ""
			meta:set_string("formspec", formspec(payload, names))
			return true
		elseif topic == "name" then
			local meta = minetest.get_meta(pos)
			return meta:get_string("player_name")
		end
	end,
	on_node_load = function(pos)
		minetest.get_node_timer(pos):start(1.0)
	end,
})		

