--[[

	Tubelib Addons 3
	================

	Copyright (C) 2017-2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	pushing_chest.lua
	
	A high performance pushing chest

]]--

-- tubelib aging feature
local AGING_LEVEL1 = 50 * tubelib.machine_aging_value
local AGING_LEVEL2 = 150 * tubelib.machine_aging_value

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

local function keep_the_rest(meta, list, taken)
	if taken then
		local inv = meta:get_inventory()	
		local rest = ItemStack(taken:get_name())
		if not inv:contains_item(list, rest) then
			inv:add_item(list, rest)
			if taken:get_count() > 1 then
				taken:set_count(taken:get_count() - 1)
				return taken
			end
		else
			return taken
		end
	end
end	

local function aging(pos, meta)
	local cnt = meta:get_int("tubelib_aging") + 1
	meta:set_int("tubelib_aging", cnt)
	if cnt > AGING_LEVEL1 and math.random(AGING_LEVEL2) == 1 then
		minetest.get_node_timer(pos):stop()
		local node = minetest.get_node(pos)
		node.name = "tubelib_addons3:pushing_chest_defect"
		minetest.swap_node(pos, node)
	end
end

local function after_dig_node(pos, oldnode, oldmetadata, digger)
	local inv = minetest.get_inventory({type="player", name=digger:get_player_name()})
	local cnt = oldmetadata.fields.tubelib_aging and tonumber(oldmetadata.fields.tubelib_aging) or 0
	local is_defect = cnt > AGING_LEVEL1 and math.random(AGING_LEVEL2 / cnt) == 1
	if is_defect then
		inv:add_item("main", ItemStack("tubelib_addons3:pushing_chest_defect"))
	else
		inv:add_item("main", ItemStack("tubelib_addons3:pushing_chest"))
	end
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
	if tubelib.data_not_corrupted(pos) then
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
						aging(pos, meta)
						return true
					else
						set_state(meta, "blocked")
					end
				end
			end
		end
		return true
	end
	return false
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

	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("main") and inv:is_empty("shift")
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		after_dig_node(pos, oldnode, oldmetadata, digger)
		tubelib.remove_node(pos)
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,

	on_timer = shift_items,
	on_rotate = screwdriver.disallow,
	
	drop = "",
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("tubelib_addons3:pushing_chest_defect", {
	description = "HighPerf Pushing Chest",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_pusher1.png^tubelib_addons3_node_frame4.png',
		'tubelib_addons3_chest_bottom.png',
		"tubelib_addons3_chest_out.png^tubelib_defect.png",
		"tubelib_addons3_chest_side.png^tubelib_defect.png",
		"tubelib_addons3_chest_side.png^tubelib_defect.png",
		"tubelib_addons3_chest_front.png^tubelib_defect.png",
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
	end,

	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local inv = minetest.get_meta(pos):get_inventory()
		return inv:is_empty("main") and inv:is_empty("shift")
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		tubelib.remove_node(pos)
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,

	on_rotate = screwdriver.disallow,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2, not_in_creative_inventory=1},
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

tubelib.register_node("tubelib_addons3:pushing_chest", 
	{"tubelib_addons3:pushing_chest_defect"}, {
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "state" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if inv:is_empty("main") then 
				return "empty"
			end
			return meta:get_string("state")
		elseif topic == "aging" then
			return minetest.get_meta(pos):get_int("tubelib_aging")
		else
			return "not supported"
		end
	end,
	on_pull_stack = function(pos, side)
		local meta = minetest.get_meta(pos)
		local taken = tubelib.get_stack(meta, "main")
		return keep_the_rest(meta, "main", taken)
	end,
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		local items = tubelib.get_num_items(meta, "main", 2)
		if items then
			-- return only one
			items:set_count(1)
			-- don't remove the potentally last item (recipe)
			tubelib.put_item(meta, "main", items)
			return items
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
	on_node_load = function(pos)
		minetest.get_node_timer(pos):start(2)
	end,
	on_node_repair = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("tubelib_aging", 0)
		meta:set_int("idx", 2)
		
		meta:set_string("formspec", formspec())
		set_state(meta, "empty")
		local node = minetest.get_node(pos)
		node.name = "tubelib_addons3:pushing_chest"
		minetest.swap_node(pos, node)
		minetest.get_node_timer(pos):start(2)
		return true
	end,
})	
