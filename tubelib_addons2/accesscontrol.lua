--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	accesscontrol.lua:
	
]]--

-- Load support for I18n
local S = tubelib_addons2.S

local function switch_on(pos, meta)
	if tubelib.data_not_corrupted(pos) then
		minetest.sound_play("tubelib_addons2_door", {
				pos = pos,
				gain = 0.5,
				max_hear_distance = 5,
			})
		local numbers = meta:get_string("numbers")
		local number = meta:get_string("number")
		local placer_name = meta:get_string("placer_name")
		tubelib.send_message(numbers, placer_name, nil, "on", number)
		minetest.get_node_timer(pos):start(4)
	end
end

local function switch_off(pos)
	if tubelib.data_not_corrupted(pos) then
		minetest.sound_play("tubelib_addons2_door", {
				pos = pos,
				gain = 0.5,
				max_hear_distance = 5,
			})
		local meta = minetest.get_meta(pos)
		local numbers = meta:get_string("numbers")
		local number = meta:get_string("number")
		local placer_name = meta:get_string("placer_name")
		tubelib.send_message(numbers, placer_name, nil, "off", number)
	end
end

local function formspec1(numbers)
	return "size[6,5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"field[0.5,1;5,1;numbers;"..S("Door block numbers:")..";"..numbers.."]" ..
	"field[0.5,2.5;5,1;code;"..S("Access code (4 digits):")..";]" ..
	"button_exit[1.5,3.5;2,1;exit;"..S("Save").."]"
end

local function formspec2(code)
	return "size[4.2,6]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"field[0.5,1;3.6,1;code;"..S("Enter access code")..";"..code.."]" ..
	"button[0.4,2;1,1;b1;1]" ..
	"button[1.6,2;1,1;b2;2]" ..
	"button[2.8,2;1,1;b3;3]" ..
	"button[0.4,3;1,1;b4;4]" ..
	"button[1.6,3;1,1;b5;5]" ..
	"button[2.8,3;1,1;b6;6]" ..
	"button[0.4,4;1,1;b7;7]" ..
	"button[1.6,4;1,1;b8;8]" ..
	"button[2.8,4;1,1;b9;9]" ..
	"button_exit[1.6,5;1,1;ok;"..S("OK").."]"
end

minetest.register_node("tubelib_addons2:accesscontrol", {
	description = S("Tubelib Access Lock"),
	tiles = {
		-- up, down, right, left, back, front
		'default_steel_block.png',
		'default_steel_block.png',
		'default_steel_block.png',
		'default_steel_block.png',
		'default_steel_block.png^tubelib_addon2_access_control.png',
		"default_steel_block.png^tubelib_addon2_access_control.png",
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons2:accesscontrol")
		local meta = minetest.get_meta(pos)
		meta:set_string("number", number)
		local numbers = meta:get_string("numbers") or ""
		meta:set_string("formspec", formspec1(numbers))
		meta:set_string("placer_name", placer:get_player_name())
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local meta = minetest.get_meta(pos)
		if meta:get_string("code") == "" then
			if fields.numbers ~= "" and fields.code ~= "" then
				if tubelib.check_numbers(fields.numbers) then
					meta:set_string("numbers", fields.numbers)
					meta:set_string("code", fields.code)
					meta:mark_as_private("code")
					meta:set_string("infotext", S("Tubelib Access Lock, Enter access code"))
					meta:set_string("formspec", formspec2(""))
				end
			end
		else
			local code = meta:get_string("input") or ""
			if fields.code == nil then
				fields.code = ""
			end
			for num = 1,9 do
				if fields["b"..num] then
					code = code..tostring(num)
					fields.code = fields.code .. "*"
				end
			end
			meta:set_string("input", code)
			if fields.quit == "true" then
				meta:set_string("input", "")
				if code == meta:get_string("code") then
					switch_on(pos, meta)
				end
				meta:set_string("formspec", formspec2(""))
			else
				meta:set_string("formspec", formspec2(fields.code))
			end
		end
	end,
	
	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,
	
	on_timer = switch_off,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})


minetest.register_craft({
	output = "tubelib_addons2:accesscontrol",
	recipe = {
		{"default:steelblock", "tubelib:wlanchip"},
	},
})

tubelib.register_node("tubelib_addons2:accesscontrol", {}, {
	on_recv_message = function(pos, topic, payload)
		if topic == "set_numbers" then
			local meta = minetest.get_meta(pos)
			meta:set_string("numbers", payload)
			meta:set_string("formspec", formspec1(payload))
			return true
		end
	end,
})		
