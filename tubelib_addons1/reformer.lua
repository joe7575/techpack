--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	reformer.lua
	
	The Reformer converts 4 Bio Gas items into one Bio Fuel item,
	needed by Harvester and Quarry.
	
]]--

local CYCLE_TIME = 6
local TICKS_TO_SLEEP = 5
local STOP_STATE = 0
local STANDBY_STATE = -1
local FAULT_STATE = -3

local function formspec(state)
	return "size[8,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;src;0,0;3,3;]"..
	"item_image[0,0;1,1;tubelib_addons1:biogas]"..
	"image[3.5,1;1,1;tubelib_gui_arrow.png]"..
	"image_button[3.5,3;1,1;".. tubelib.state_button(state) ..";button;]"..
	"list[context;dst;5,0;3,3;]"..
	"item_image[5,0;1,1;tubelib_addons1:biofuel]"..
	"list[current_player;main;0,4.3;8,4;]"..
	"listring[context;dst]"..
	"listring[current_player;main]"..
	"listring[context;src]"..
	"listring[current_player;main]"
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if listname == "src" and stack:get_name() == "tubelib_addons1:biogas" then
		return stack:get_count()
	elseif listname == "dst" then
		return stack:get_count()
	end
	return 0
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end


local function place_top(pos, facedir, placer)
	if minetest.is_protected(pos, placer:get_player_name()) then
		return false
	end
	local node = minetest.get_node(pos)
	if node.name ~= "air" then
		return false
	end
	minetest.add_node(pos, {name="tubelib_addons1:reformer_top", param2=facedir})
	return true
end

local function convert_biogas_to_biofuel(meta)
	local inv = meta:get_inventory()
	local biofuel = ItemStack("tubelib_addons1:biofuel")
	if inv:room_for_item("dst", biofuel) then						-- enough output space?
		local items = tubelib.get_num_items(meta, "src", 4)
		if items then												-- input available?
			if items:get_name() == "tubelib_addons1:biogas" then	-- valid input?
				inv:add_item("dst", biofuel)
				return true
			else
				inv:add_item("src", items)
				return nil  										-- error
			end
		else
			return false  											-- standby
		end
	else
		return false  												-- standby
	end
end

local function start_the_machine(pos)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", TICKS_TO_SLEEP)
	meta:set_string("infotext", "Tubelib Reformer "..number..": running")
	meta:set_string("formspec", formspec(tubelib.RUNNING))
	minetest.get_node_timer(pos):start(CYCLE_TIME)
	return false
end

local function stop_the_machine(pos)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", STOP_STATE)
	minetest.get_node_timer(pos):stop()
	meta:set_string("infotext", "Tubelib Reformer "..number..": stopped")
	meta:set_string("formspec", formspec(tubelib.STOPPED))
	return false
end

local function goto_sleep(pos)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", STANDBY_STATE)
	minetest.get_node_timer(pos):start(CYCLE_TIME * TICKS_TO_SLEEP)
	meta:set_string("infotext", "Tubelib Reformer "..number..": standby")
	meta:set_string("formspec", formspec(tubelib.STANDBY))
	return false
end

local function goto_fault(pos)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", FAULT_STATE)
	minetest.get_node_timer(pos):stop()
	meta:set_string("infotext", "Tubelib Reformer "..number..": fault")
	meta:set_string("formspec", formspec(tubelib.FAULT))
	return false
end

local function keep_running(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local running = meta:get_int("running") - 1
	local res = convert_biogas_to_biofuel(meta)
	
	if res == true then 
		if running <= STOP_STATE then
			return start_the_machine(pos)
		else
			running = TICKS_TO_SLEEP
		end
	elseif res == false then
		if running <= STOP_STATE then
			local node = minetest.get_node(pos)
			return goto_sleep(pos, node)
		end
	else
		return goto_fault(pos)
	end
	meta:set_int("running", running)
	meta:set_string("formspec", formspec(tubelib.RUNNING))
	return true
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local meta = minetest.get_meta(pos)
	local running = meta:get_int("running") or STOP_STATE
	if fields.button ~= nil then
		if running > STOP_STATE or running == FAULT_STATE then
			stop_the_machine(pos)
		else
			start_the_machine(pos)
		end
	end
end


minetest.register_node("tubelib_addons1:reformer", {
	description = "Tubelib Reformer",
	inventory_image = "tubelib_addons1_reformer_inventory.png",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_addons1_reformer1_bottom.png',
		'tubelib_addons1_reformer1_bottom.png',
		'tubelib_addons1_reformer2_bottom.png',
		'tubelib_addons1_reformer2_bottom.png',
	},

	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, -8/16,   8/16, 24/16, 8/16 },
	},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size('src', 9)
		inv:set_size('dst', 9)
	end,
	
	after_place_node = function(pos, placer)
		local facedir = minetest.dir_to_facedir(placer:get_look_dir(), false)
		if place_top({x=pos.x, y=pos.y+1, z=pos.z}, facedir, placer) == false then
			minetest.remove_node(pos)
			return
		end
		local number = tubelib.add_node(pos, "tubelib_addons1:reformer")
		local meta = minetest.get_meta(pos)
		meta:set_string("number", number)
		meta:set_int("running", STOP_STATE)
		meta:set_string("infotext", "Tubelib Reformer "..number..": stopped")
		meta:set_string("formspec", formspec(tubelib.STOPPED))
	end,

	on_dig = function(pos, node, puncher, pointed_thing)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if inv:is_empty("dst") and inv:is_empty("src") then
			minetest.node_dig(pos, node, puncher, pointed_thing)
			minetest.remove_node({x=pos.x, y=pos.y+1, z=pos.z})
			tubelib.remove_node(pos)
		end
	end,
	
	on_rotate = screwdriver.disallow,
	on_timer = keep_running,
	on_receive_fields = on_receive_fields,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})


minetest.register_node("tubelib_addons1:reformer_top", {
	description = "Tubelib Reformer Top",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		"tubelib_front.png",
		'tubelib_addons1_reformer1_top.png',
		'tubelib_addons1_reformer1_top.png',
		'tubelib_addons1_reformer2_top.png',
		'tubelib_addons1_reformer2_top.png',
	},

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	pointable = false,
})

minetest.register_craftitem("tubelib_addons1:biofuel", {
	description = "Bio Fuel",
	inventory_image = "tubelib_addons1_biofuel.png",
})

minetest.register_craft({
	type = "fuel",
	recipe = "tubelib_addons1:biofuel",
	burntime = 12,
})


minetest.register_craft({
	output = "tubelib_addons1:reformer",
	recipe = {
		{"default:steel_ingot", "default:clay",  		"default:steel_ingot"},
		{"tubelib:tube1", 		"default:mese_crystal",	"tubelib:tube1"},
		{"default:steel_ingot", "group:wood",  			"default:steel_ingot"},
	},
})


tubelib.register_node("tubelib_addons1:reformer", {}, {
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		return tubelib.get_item(meta, "dst")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "src", item)
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "dst", item)
	end,
	on_recv_message = function(pos, topic, payload)
		if topic == "on" then
			start_the_machine(pos)
		elseif topic == "off" then
			stop_the_machine(pos)
		elseif topic == "state" then
			local meta = minetest.get_meta(pos)
			local running = meta:get_int("running")
			return tubelib.statestring(running)
		else
			return "unsupported"
		end
	end,
})	
