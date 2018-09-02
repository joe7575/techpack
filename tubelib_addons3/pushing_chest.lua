--[[

	Tubelib Addons 3
	================

	Copyright (C) 2017-2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	pushing_chest.lua
	
	A high performance pushing chest

]]--


local Cache = {}

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	Cache[minetest.get_meta(pos):get_string("number")] = nil
	minetest.log("action", player:get_player_name().." moves "..stack:get_name()..
			" to chest at "..minetest.pos_to_string(pos))
	return stack:get_count()
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	Cache[minetest.get_meta(pos):get_string("number")] = nil
	minetest.log("action", player:get_player_name().." takes "..stack:get_name()..
			" from chest at "..minetest.pos_to_string(pos))
	return stack:get_count()
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	Cache[minetest.get_meta(pos):get_string("number")] = nil
	return count
end	

local function set_state(meta, state)
	local number = meta:get_string("number")
	meta:set_string("infotext", "HighPerf Pushing Chest "..number..": "..state)
	meta:set_string("state", state)
end	

local function configured(pos, item)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local number = meta:get_string("number")
	if not Cache[number] then
		Cache[number] = {}
		for _,items in ipairs(inv:get_list("main")) do
			Cache[number][items:get_name()] = true
		end
	end
	return Cache[number][item:get_name()] == true
end

local function shift_items(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if not inv:is_empty("shift") then
		local number = meta:get_string("number")
		local player_name = meta:get_string("player_name")
		local offs = meta:get_int("offs")
		meta:set_int("offs", offs + 1)
		for i = 0,7 do
			local idx = ((i + offs) % 8) + 1
			local stack = inv:get_stack("shift", idx)
			if stack:get_count() > 0 then
				if tubelib.push_items(pos, "R", stack, player_name) then
					-- The effort is needed here for the case the 
					-- pusher pushes into its own chest.
					local num = stack:get_count()
					stack = inv:get_stack("shift", idx)
					stack:take_item(num)
					inv:set_stack("shift", idx, stack)
					return true
				else
					set_state(meta, "blocked")
				end
			end
		end
	end
	return true
end

local function formspec()
	return "size[9,9.2]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;shift;0.5,0;8,1;]"..
	"list[context;main;0.5,1.2;8,4;]"..
	"image[0.5,0;1,1;tubelib_gui_arrow.png]"..
	"image[7.5,0;1,1;tubelib_gui_arrow.png]"..
	"list[current_player;main;0.5,5.5;8,4;]"..
	"image[0.5,1.2;1,1;tubelib_gui_arrow.png^[transformR270]"..
	"listring[context;main]"..
	"listring[current_player;main]"
end

minetest.register_node("tubelib_addons3:pushing_chest", {
	description = "HighPerf Pushing Chest",
	tiles = {
		-- up, down, right, left, back, front
		{
			image = "tubelib_addons3_pusher_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 2.0,
			},
		},
		'tubelib_addons3_chest_bottom.png',
		"tubelib_addons3_chest_out.png",
		"tubelib_addons3_chest_side.png",
		"tubelib_addons3_chest_side.png",
		"tubelib_addons3_chest_front.png",
	},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size('main', 32)
		inv:set_size('shift', 8)
	end,
	
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local number = tubelib.add_node(pos, "tubelib_addons3:pushing_chest")	
		meta:set_string("player_name", placer:get_player_name())
		meta:set_string("number", number)
		meta:set_string("formspec", formspec())
		set_state(meta, "empty")
		minetest.get_node_timer(pos):start(2)
	end,

	can_dig = function(pos,player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main") and inv:is_empty("shift")
	end,
	
	on_dig = function(pos, node, puncher, pointed_thing)
		minetest.node_dig(pos, node, puncher, pointed_thing)
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,

	on_timer = shift_items,
	on_rotate = screwdriver.disallow,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_craft({
	output = "tubelib_addons3:pushing_chest",
	recipe = {
		{"default:tin_ingot", "tubelib_addons3:pusher", ""},
		{"tubelib_addons1:chest", "default:gold_ingot", ""},
		{"", "", ""},
	},
})

tubelib.register_node("tubelib_addons3:pushing_chest", {}, {
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "state" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if inv:is_empty("main") then 
				return "empty"
			end
			return meta:get_string("state")
		else
			return "not supported"
		end
	end,
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		local item = tubelib.get_item(meta, "main")
		-- check if one remaining item is left
		if meta:get_inventory():contains_item("main", item) then
			return item 
		else
			-- don't remove the last item (recipe)
			tubelib.put_item(meta, "main", item)
			return nil 
		end
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		if configured(pos, item) then
			if tubelib.put_item(meta, "main", item) then
				set_state(meta, "loaded")
				return true
			else
				set_state(meta, "full")
				return tubelib.put_item(meta, "shift", item)
			end
		else
			return tubelib.put_item(meta, "shift", item)
		end
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
	
	on_recv_message = function(pos, topic, payload)
		return "unsupported"
	end,
})	
