--[[

	SmartLine
	=========

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	collector.lua:
	
	Collects states from other nodes, acting as a state concentrator.

]]--

-- Load support for I18n
local S = smartline.S

local CYCLE_TIME = 1

local tStates = {stopped = 0, running = 0, standby = 1, blocked = 2, fault = 3, defect = 4}
local tDropdownPos = {["1 standby"] = 1, ["2 blocked"] = 2 , ["3 fault"] = 3, ["4 defect"] = 4}
local lStates = {[0] = "stopped", "standby", "blocked", "fault", "defect"}
	
local function formspec(meta)
	local poll_numbers = meta:get_string("poll_numbers")
	local event_number = meta:get_string("event_number")
	local dropdown_pos = meta:get_int("dropdown_pos")
	if dropdown_pos == 0 then dropdown_pos = 1 end
	
	return "size[9,6]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"field[0.3,0.6;9,1;poll_numbers;"..S("Node numbers to read the states from:")..";"..poll_numbers.."]" ..
		"field[0.3,2;9,1;event_number;"..S("Node number to send the events to:")..";"..event_number.."]" ..
		"label[1.3,2.8;"..S("Send an event if state is equal or larget than:").."]"..
		"dropdown[1.2,3.4;7,4;severity;1 standby,2 blocked,3 fault,4 defect;"..dropdown_pos.."]"..
		"button_exit[3,5;2,1;exit;"..S("Save").."]"
end	


local function send_event(meta)
	local event_number = meta:get_string("event_number")
	if event_number ~= "" then
		local state = meta:get_int("state")
		local severity = meta:get_int("dropdown_pos")
		local owner = meta:get_string("owner")
		local own_number = meta:get_string("own_number")
		if state >= severity then
			tubelib.send_message(event_number, owner, nil, "on", own_number)
		else
			tubelib.send_message(event_number, owner, nil, "off", own_number)
		end
		meta:set_string("infotext", S("SmartLine State Collector").." "..own_number..': "'..lStates[state]..'"')
		meta:set_int("stored_state", state)
		meta:set_int("state", 0)
	end
end

local function request_state(meta, poll_numbers, idx)
	local number = string.split(poll_numbers, " ")[idx]
	local state = tubelib.send_request(number, "state", nil)
	if state then
		state = tStates[state] or 0
		meta:set_int("state", math.max(meta:get_int("state"), state))
	end
end


local function on_timer(pos,elapsed)
	if tubelib.data_not_corrupted(pos) then
		local meta = minetest.get_meta(pos)
		local poll_numbers = meta:get_string("poll_numbers")
		local idx = meta:get_int("index") + 1
		
		if poll_numbers == "" then
			local own_number = meta:get_string("own_number")
			meta:set_string("infotext", S("SmartLine State Collector").." "..own_number..": stopped")
			meta:set_int("state", 0)
			meta:set_int("stored_state", 0)
			return false
		end
		
		if idx > meta:get_int("num_numbers") then
			idx = 1
			send_event(meta)
		end
		meta:set_int("index", idx)
		
		request_state(meta, poll_numbers, idx)
		
		return true
	end
	return false
end

minetest.register_node("smartline:collector", {
	description = S("SmartLine State Collector"),
	inventory_image = "smartline_collector_inventory.png",
	tiles = {
		-- up, down, right, left, back, front
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png",
		"smartline.png^smartline_collector.png",
	},

	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -6/32, -6/32, 14/32,  6/32,  6/32, 16/32},
		},
	},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local own_number = tubelib.add_node(pos, "smartline:collector")
		meta:set_string("own_number", own_number)
		meta:set_string("poll_numbers", "")
		meta:set_string("event_number", "")
		meta:set_string("formspec", formspec(meta))
		meta:set_string("infotext", S("SmartLine State Collector").." "..own_number)
		meta:set_string("owner", placer:get_player_name())
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		local timer = minetest.get_node_timer(pos)
		local own_number = meta:get_string("own_number")
		if owner ~= player:get_player_name() then
			return
		end

		if fields.quit == "true" and fields.poll_numbers then
			if tubelib.check_numbers(fields.event_number) then
				meta:set_string("event_number", fields.event_number)
			end
			if tubelib.check_numbers(fields.poll_numbers) then
				meta:set_string("poll_numbers", fields.poll_numbers)
				meta:set_int("index", 0)
				meta:set_int("num_numbers", #string.split(fields.poll_numbers, " "))
				if not timer:is_started() then
					timer:start(CYCLE_TIME)
				end
				meta:set_string("infotext", S("SmartLine State Collector").." "..own_number..": running")
			else
				if timer:is_started() then
					timer:stop()
				end
				meta:set_string("infotext", "SmartLine State Collector "..own_number..": stopped")
				meta:set_int("stored_state", 0)
			end
			if fields.severity then
				meta:set_int("dropdown_pos", tDropdownPos[fields.severity])
			end
			meta:set_string("formspec", formspec(meta))
		end
		
	end,
	
	on_timer = on_timer,
	
	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
})


minetest.register_craft({
	output = "smartline:collector",
	recipe = {
		{"", "default:copper_ingot", ""},
		{"tubelib:wlanchip", "dye:blue", "tubelib:wlanchip"},
		{"", "default:copper_ingot", ""},
	},
})

tubelib.register_node("smartline:collector", {}, {
	on_recv_message = function(pos, topic, payload)
		if topic == "set_numbers" then
			local meta = minetest.get_meta(pos)
			if tubelib.check_numbers(payload) then
				meta:set_string("poll_numbers", payload)
				meta:set_string("formspec", formspec(meta))
				meta:set_int("num_numbers", #string.split(payload, " "))
				minetest.get_node_timer(pos):start(CYCLE_TIME)
			end
			return true
		elseif topic == "state" then
			local meta = minetest.get_meta(pos)
			local state = meta:get_int("stored_state")
			return lStates[state]
		else
			return "unsupported"
		end
	end,
	on_node_load = function(pos)
		minetest.get_node_timer(pos):start(CYCLE_TIME)
	end,
})		
