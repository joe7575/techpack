--[[

	Tubelib Addons 3
	================

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	chest.lua
	
	A high performance chest

]]--


local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	minetest.log("action", player:get_player_name().." moves "..stack:get_name()..
			" to chest at "..minetest.pos_to_string(pos))
	return stack:get_count()
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	minetest.log("action", player:get_player_name().." takes "..stack:get_name()..
			" from chest at "..minetest.pos_to_string(pos))
	return stack:get_count()
end

local function get_stack(meta, list)
	local inv = meta:get_inventory()
	local item = tubelib.get_item(meta, list)
	if item and inv:contains_item(list, item) then
		-- try to remove a complete stack
		item:set_count(98)
		local taken = inv:remove_item(list, item)
		-- add the already removed
		taken:set_count(taken:get_count() + 1)
		return taken
	end
	return item 
end


local function formspec()
	return "size[12,10]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;main;0,0;12,6;]"..
	"list[current_player;main;2,6.3;8,4;]"..
	"listring[context;main]"..
	"listring[current_player;main]"
end

minetest.register_node("tubelib_addons3:chest", {
	description = "HighPerf Chest",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_addons3_chest_bottom.png',
		'tubelib_addons3_chest_bottom.png',
		"tubelib_addons3_chest_side.png",
		"tubelib_addons3_chest_side.png",
		"tubelib_addons3_chest_side.png",
		"tubelib_addons3_chest_front.png",
	},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size('main', 72)
	end,
	
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", formspec())
		meta:set_string("infotext", "HighPerf Chest")
	end,

	can_dig = function(pos,player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	
	on_dig = function(pos, node, puncher, pointed_thing)
		minetest.node_dig(pos, node, puncher, pointed_thing)
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_craft({
	output = "tubelib_addons3:chest",
	recipe = {
		{"", "default:steel_ingot", ""},
		{"tubelib_addons1:chest", "default:gold_ingot", "tubelib_addons1:chest"},
		{"", "default:tin_ingot", ""},
	}
})

tubelib.register_node("tubelib_addons3:chest", {}, {
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		return get_stack(meta, "main")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		tubelib.put_item(meta, "main", item)
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
	
	on_recv_message = function(pos, topic, payload)
		return "unsupported"
	end,
})	
