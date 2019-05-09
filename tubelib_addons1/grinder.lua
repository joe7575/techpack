--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017-2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	grinder.lua
	
	Grinding Cobble to Gravel
	
]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

local STANDBY_TICKS = 4
local COUNTDOWN_TICKS = 4
local CYCLE_TIME = 2


-- Grinder recipes
local Recipes = {}

local function formspec(self, pos, meta)
	return "size[8,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;src;0,0;3,3;]"..
	"item_image[0,0;1,1;default:cobble]"..
	"image[3.5,1;1,1;tubelib_gui_arrow.png]"..
	"image_button[3.5,2;1,1;".. self:get_state_button_image(meta) ..";state_button;]"..
	"list[context;dst;5,0;3,3;]"..
	"item_image[5,0;1,1;default:gravel]"..
	"list[current_player;main;0,4;8,4;]"..
	"listring[context;dst]"..
	"listring[current_player;main]"..
	"listring[context;src]"..
	"listring[current_player;main]"
end

local State = tubelib.NodeStates:new({
	node_name_passive = "tubelib_addons1:grinder",
	node_name_active = "tubelib_addons1:grinder_active",
	node_name_defect = "tubelib_addons1:grinder_defect",
	infotext_name = "Tubelib Grinder",
	cycle_time = CYCLE_TIME,
	standby_ticks = STANDBY_TICKS,
	has_item_meter = true,
	aging_factor = 10,
	formspec_func = formspec,
})

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	if listname == "src" and State:get_state(M(pos)) == tubelib.STANDBY then
		State:start(pos, M(pos))
	end
	return stack:get_count()
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local inv = M(pos):get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function grinding(pos, meta, inv)
	for _,stack in ipairs(inv:get_list("src")) do
		if not stack:is_empty() then
			local name = stack:get_name()
			if Recipes[name] then
				local output = Recipes[name]
				if inv:room_for_item("dst", output) then
					inv:add_item("dst", output)
					inv:remove_item("src", ItemStack(name))
					State:keep_running(pos, meta, COUNTDOWN_TICKS)
				else
					State:blocked(pos, meta)
				end
			else
				State:fault(pos, meta)
			end
			return
		end
	end
	State:idle(pos, meta)
end

local function keep_running(pos, elapsed)
	if tubelib.data_not_corrupted(pos) then
		local meta = M(pos)
		local inv = meta:get_inventory()
		grinding(pos, meta, inv)
		return State:is_active(meta)
	end
	return false
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	State:state_button_event(pos, fields)
end

minetest.register_node("tubelib_addons1:grinder", {
	description = "Tubelib Grinder",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_addons1_grinder.png',
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png',
		"tubelib_front.png",
		"tubelib_front.png",
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons1:grinder")
		State:node_init(pos, number)
		local inv = M(pos):get_inventory()
		inv:set_size('src', 9)
		inv:set_size('dst', 9)
	end,

	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local inv = M(pos):get_inventory()
		return inv:is_empty("dst") and inv:is_empty("src")
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		State:after_dig_node(pos, oldnode, oldmetadata, digger)
		tubelib.remove_node(pos)
	end,
	
	on_rotate = screwdriver.disallow,
	on_timer = keep_running,
	on_receive_fields = on_receive_fields,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	drop = "",
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_node("tubelib_addons1:grinder_active", {
	description = "Tubelib Grinder",
	tiles = {
		-- up, down, right, left, back, front
		{
			image = 'tubelib_addons1_grinder_active.png',
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 1.0,
			},
		},
		
		'tubelib_front.png',
		"tubelib_front.png",
		"tubelib_front.png",
		"tubelib_front.png",
		"tubelib_front.png",
	},

	on_rotate = screwdriver.disallow,
	on_timer = keep_running,
	on_receive_fields = on_receive_fields,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("tubelib_addons1:grinder_defect", {
	description = "Tubelib Grinder",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_addons1_grinder.png',
		'tubelib_front.png',
		'tubelib_front.png^tubelib_defect.png',
		'tubelib_front.png^tubelib_defect.png',
		"tubelib_front.png^tubelib_defect.png",
		"tubelib_front.png^tubelib_defect.png",
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons1:grinder")
		State:node_init(pos, number)
		local meta = M(pos)
		local inv = meta:get_inventory()
		inv:set_size('src', 9)
		inv:set_size('dst', 9)
		State:defect(pos, meta)
	end,

	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local inv = M(pos):get_inventory()
		return inv:is_empty("dst") and inv:is_empty("src")
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		tubelib.remove_node(pos)
	end,
	
	on_rotate = screwdriver.disallow,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	output = "tubelib_addons1:grinder",
	recipe = {
		{"group:wood", "default:tin_ingot", "group:wood"},
		{"tubelib:tubeS", "default:mese_crystal", "tubelib:tubeS"},
		{"group:wood", "default:tin_ingot", "group:wood"},
	},
})


tubelib.register_node("tubelib_addons1:grinder", 
	{"tubelib_addons1:grinder_active", "tubelib_addons1:grinder_defect"}, {
	on_pull_stack = function(pos, side)
		return tubelib.get_stack(M(pos), "dst")
	end,
	on_pull_item = function(pos, side)
		return tubelib.get_item(M(pos), "dst")
	end,
	on_push_item = function(pos, side, item)
		return tubelib.put_item(M(pos), "src", item)
	end,
	on_unpull_item = function(pos, side, item)
		return tubelib.put_item(M(pos), "dst", item)
	end,
	on_recv_message = function(pos, topic, payload)
		local resp = State:on_receive_message(pos, topic, payload)
		if resp then
			return resp
		else
			return "unsupported"
		end
	end,
	on_node_load = function(pos)
		State:on_node_load(pos)
	end,
	on_node_repair = function(pos)
		return State:on_node_repair(pos)
	end,
})	


if minetest.global_exists("unified_inventory") then
	unified_inventory.register_craft_type("grinding", {
		description = "Grinding",
		icon = 'tubelib_addons1_grinder.png',
		width = 1,
		height = 1,
	})
end

function tubelib.add_grinder_recipe(recipe)
	Recipes[recipe.input] =  ItemStack(recipe.output)
	if minetest.global_exists("unified_inventory") then
		recipe.items = {recipe.input}
		recipe.type = "grinding"
		unified_inventory.register_craft(recipe)
	end
end	


tubelib.add_grinder_recipe({input="default:cobble", output="default:gravel"})
tubelib.add_grinder_recipe({input="default:desert_cobble", output="default:gravel"})
tubelib.add_grinder_recipe({input="default:mossycobble", output="default:gravel"})
tubelib.add_grinder_recipe({input="default:gravel", output="default:sand"})
tubelib.add_grinder_recipe({input="gravelsieve:sieved_gravel", output="default:sand"})
tubelib.add_grinder_recipe({input="default:coral_skeleton", output="default:silver_sand"})
tubelib.add_grinder_recipe({input="tubelib:basalt_stone", output="default:silver_sand"})

if minetest.global_exists("skytest") then
	tubelib.add_grinder_recipe({input="default:desert_sand", output="skytest:dust"})
	tubelib.add_grinder_recipe({input="default:silver_sand", output="skytest:dust"})
	tubelib.add_grinder_recipe({input="default:sand", output="skytest:dust"})
	tubelib.add_grinder_recipe({input="skytest:dust 12", output="skytest:powder"})
else
	tubelib.add_grinder_recipe({input="default:desert_sand", output="default:clay"})
	tubelib.add_grinder_recipe({input="default:silver_sand", output="default:clay"})
	tubelib.add_grinder_recipe({input="default:sand", output="default:clay"})
end

tubelib.add_grinder_recipe({input="default:sandstone", output="default:sand 4"})
tubelib.add_grinder_recipe({input="default:desert_sandstone", output="default:desert_sand 4"})
tubelib.add_grinder_recipe({input="default:silver_sandstone", output="default:silver_sand 4"})

tubelib.add_grinder_recipe({input="default:tree", output="default:leaves 8"})
tubelib.add_grinder_recipe({input="default:jungletree", output="default:jungleleaves 8"})
tubelib.add_grinder_recipe({input="default:pine_tree", output="default:pine_needles 8"})
tubelib.add_grinder_recipe({input="default:acacia_tree", output="default:acacia_leaves 8"})
tubelib.add_grinder_recipe({input="default:aspen_tree", output="default:aspen_leaves 8"})
