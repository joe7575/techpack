--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017,2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	grinder.lua
	
	Grinding Cobble to Gravel
	
]]--

local TICKS_TO_SLEEP = 10
local CYCLE_TIME = 2
local STOP_STATE = 0
local STANDBY_STATE = -1
local FAULT_STATE = -3

-- Grinder recipes
local Recipes = {}

local function formspec(state)
	return "size[8,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;src;0,0;3,3;]"..
	"item_image[0,0;1,1;default:cobble]"..
	"image[3.5,1;1,1;tubelib_gui_arrow.png]"..
	"image_button[3.5,2;1,1;".. tubelib.state_button(state) ..";button;]"..
	"list[context;dst;5,0;3,3;]"..
	"item_image[5,0;1,1;default:gravel]"..
	"list[current_player;main;0,4;8,4;]"..
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
	if listname == "src" then
		return stack:get_count()
	elseif listname == "dst" then
		return 0
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

local function grinding(inv)
	for _,stack in ipairs(inv:get_list("src")) do
		if not stack:is_empty() then
			local name = stack:get_name()
			if Recipes[name] then
				local output = Recipes[name]
				if inv:room_for_item("dst", output) then
					inv:add_item("dst", output)
					inv:remove_item("src", ItemStack(name))
					return true
				end
			end
		end
	end
	return false
end


local function start_the_machine(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local number = meta:get_string("number")
	meta:set_int("running", TICKS_TO_SLEEP)
	meta:set_string("infotext", "Tubelib Grinder "..number..": running")
	meta:set_string("formspec", formspec(tubelib.RUNNING))
	node.name = "tubelib_addons1:grinder_active"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):start(CYCLE_TIME)
	return false
end

local function stop_the_machine(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local number = meta:get_string("number")
	meta:set_int("running", STOP_STATE)
	meta:set_string("infotext", "Tubelib Grinder "..number..": stopped")
	meta:set_string("formspec", formspec(tubelib.STOPPED))
	node.name = "tubelib_addons1:grinder"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):stop()
	return false
end

local function goto_sleep(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local number = meta:get_string("number")
	meta:set_int("running", STANDBY_STATE)
	meta:set_string("infotext", "Tubelib Grinder "..number..": standby")
	meta:set_string("formspec", formspec(tubelib.STANDBY))
	node.name = "tubelib_addons1:grinder"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):start(CYCLE_TIME * TICKS_TO_SLEEP)
	return false
end

local function goto_fault(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local number = meta:get_string("number")
	meta:set_int("running", FAULT_STATE)
	meta:set_string("infotext", "Tubelib Grinder "..number..": fault")
	meta:set_string("formspec", formspec(tubelib.FAULT))
	node.name = "tubelib_addons1:grinder"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):stop()
	return false
end

local function keep_running(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local running = meta:get_int("running") - 1
	--print("running", running)
	local inv = meta:get_inventory()
	local busy = grinding(inv)
	
	if busy == true then 
		if running <= STOP_STATE then
			return start_the_machine(pos)
		else
			running = TICKS_TO_SLEEP
		end
	elseif not inv:is_empty("src") then
		return goto_fault(pos)
	else
		if running <= STOP_STATE then
			return goto_sleep(pos)
		end
	end
	meta:set_int("running", running)
	return true
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local meta = minetest.get_meta(pos)
	local running = meta:get_int("running") or 1
	if fields.button ~= nil then
		if running > STOP_STATE or running == FAULT_STATE then
			stop_the_machine(pos)
		else
			start_the_machine(pos)
		end
	end
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
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size('src', 9)
		inv:set_size('dst', 9)
		meta:set_string("number", number)
		meta:set_string("infotext", "Tubelib Grinder "..number..": stopped")
		meta:set_string("formspec", formspec(tubelib.STOPPED))
	end,

	on_dig = function(pos, node, puncher, pointed_thing)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if inv:is_empty("dst") and inv:is_empty("src") then
			minetest.node_dig(pos, node, puncher, pointed_thing)
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

minetest.register_craft({
	output = "tubelib_addons1:grinder",
	recipe = {
		{"group:wood", 		"default:tin_ingot",  	"group:wood"},
		{"tubelib:tube1", 	"default:mese_crystal",	"tubelib:tube1"},
		{"group:wood", 		"default:tin_ingot",  	"group:wood"},
	},
})


tubelib.register_node("tubelib_addons1:grinder", {"tubelib_addons1:grinder_active"}, {
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

tubelib.add_grinder_recipe({input="default:sandstone", output="default:sand"})
tubelib.add_grinder_recipe({input="default:desert_sandstone", output="default:desert_sand"})
tubelib.add_grinder_recipe({input="default:silver_sandstone", output="default:silver_sand"})

tubelib.add_grinder_recipe({input="default:tree", output="default:leaves 8"})
tubelib.add_grinder_recipe({input="default:jungletree", output="default:jungleleaves 8"})
tubelib.add_grinder_recipe({input="default:pine_tree", output="default:pine_needles 8"})
tubelib.add_grinder_recipe({input="default:acacia_tree", output="default:acacia_leaves 8"})
tubelib.add_grinder_recipe({input="default:aspen_tree", output="default:aspen_leaves 8"})
