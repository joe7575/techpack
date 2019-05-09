--[[

	Tubelib Addons
	==============

	Copyright (C) 2017-2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	The autocrafter is derived from pipeworks: 
	Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>  WTFPL

	autocrafter.lua:
	
]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

local STANDBY_TICKS = 6
local COUNTDOWN_TICKS = 6
local CYCLE_TIME = 2

local function formspec(self, pos, meta)
	return "size[8,9.2]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[context;recipe;0,0;3,3;]"..
		"image[2.8,1;1,1;tubelib_gui_arrow.png]"..
		"list[context;output;3.5,1;1,1;]"..
		"image_button[3.5,2;1,1;".. self:get_state_button_image(meta) ..";state_button;]"..
		"list[context;src;0,3.2;8,2;]"..
		"list[context;dst;5,0;3,3;]"..
		"list[current_player;main;0,5.4;8,4;]" ..
		"listring[current_player;main]"..
		"listring[context;src]" ..
		"listring[current_player;main]"..
		"listring[context;dst]" ..
		"listring[current_player;main]"
end

local State = tubelib.NodeStates:new({
	node_name_passive = "tubelib_addons1:autocrafter",
	node_name_active = "tubelib_addons1:autocrafter_active",
	node_name_defect = "tubelib_addons1:autocrafter_defect",
	infotext_name = "Tubelib Autocrafter",
	cycle_time = CYCLE_TIME,
	standby_ticks = STANDBY_TICKS,
	has_item_meter = true,
	aging_factor = 10,
	start_condition_fullfilled = function(pos, meta)
		local output = meta:get_inventory():get_stack("output", 1)
		if output:is_empty() then -- no recipe?
			return false
		end
		return true
	end,
	formspec_func = formspec,
})


local function count_index(invlist)
	local index = {}
	for _, stack in pairs(invlist) do
		if not stack:is_empty() then
			local stack_name = stack:get_name()
			index[stack_name] = (index[stack_name] or 0) + stack:get_count()
		end
	end
	return index
end

-- caches some recipe data
local autocrafterCache = {}  

local function get_craft(pos, inventory, hash)
	hash = hash or minetest.hash_node_position(pos)
	local craft = autocrafterCache[hash]
	if not craft then
		local recipe = inventory:get_list("recipe")
		local output, decremented_input = minetest.get_craft_result(
				{method = "normal", width = 3, items = recipe})
		craft = {recipe = recipe, consumption=count_index(recipe), 
				output = output, decremented_input = decremented_input}
		autocrafterCache[hash] = craft
	end
	return craft
end

local function autocraft(pos, meta, inventory, craft)
	if not craft then return false end
	local output_item = craft.output.item

	-- check if we have enough room in dst
	if not inventory:room_for_item("dst", output_item) then	
		State:blocked(pos, meta)
		return
	end
	local consumption = craft.consumption
	local inv_index = count_index(inventory:get_list("src"))
	-- check if we have enough material available
	for itemname, number in pairs(consumption) do
		if (not inv_index[itemname]) or inv_index[itemname] < number then 
			State:idle(pos, meta)
			return 
		end
	end
	-- consume material
	for itemname, number in pairs(consumption) do
		for i = 1, number do -- We have to do that since remove_item does not work if count > stack_max
			inventory:remove_item("src", ItemStack(itemname))
		end
	end

	-- craft the result into the dst inventory and add any "replacements" as well
	inventory:add_item("dst", output_item)
	for i = 1, 9 do
		inventory:add_item("dst", craft.decremented_input.items[i])
	end
	
	State:keep_running(pos, meta, COUNTDOWN_TICKS, output_item:get_count())
end


local function keep_running(pos, elapsed)
	if tubelib.data_not_corrupted(pos) then
		local meta = M(pos)
		local inv = meta:get_inventory()
		local craft = get_craft(pos, inv)
		local output_item = craft.output.item
		autocraft(pos, meta, inv, craft)
		return State:is_active(meta)
	end
	return false
end

-- note, that this function assumes allready being updated to virtual items
-- and doesn't handle recipes with stacksizes > 1
local function after_recipe_change(pos, inventory)
	local meta = M(pos)
	-- if we emptied the grid, there's no point in keeping it running or cached
	if inventory:is_empty("recipe") then
		autocrafterCache[minetest.hash_node_position(pos)] = nil
		inventory:set_stack("output", 1, "")
		State:stop(pos, meta)
		return
	end
	local recipe_changed = false
	local recipe = inventory:get_list("recipe")

	local hash = minetest.hash_node_position(pos)
	local craft = autocrafterCache[hash]

	if craft then
		-- check if it changed
		local cached_recipe = craft.recipe
		for i = 1, 9 do
			if recipe[i]:get_name() ~= cached_recipe[i]:get_name() then
				autocrafterCache[hash] = nil -- invalidate recipe
				craft = nil
				break
			end
		end
	end

	craft = craft or get_craft(pos, inventory, hash)
	local output_item = craft.output.item
	inventory:set_stack("output", 1, output_item)
	State:stop(pos, meta)
end

-- clean out unknown items and groups, which would be handled like unknown items in the crafting grid
-- if minetest supports query by group one day, this might replace them
-- with a canonical version instead
local function normalize(item_list)
	for i = 1, #item_list do
		local name = item_list[i]
		if not minetest.registered_items[name] then
			item_list[i] = ""
		end
	end
	return item_list
end

local function on_output_change(pos, inventory, stack)
	if not stack then
		inventory:set_list("output", {})
		inventory:set_list("recipe", {})
	else
		local input = minetest.get_craft_recipe(stack:get_name())
		if not input.items or input.type ~= "normal" then return end
		local items, width = normalize(input.items), input.width
		local item_idx, width_idx = 1, 1
		for i = 1, 9 do
			if width_idx <= width then
				inventory:set_stack("recipe", i, items[item_idx])
				item_idx = item_idx + 1
			else
				inventory:set_stack("recipe", i, ItemStack(""))
			end
			width_idx = (width_idx < 3) and (width_idx + 1) or 1
		end
		-- we'll set the output slot in after_recipe_change to the actual result of the new recipe
	end
	after_recipe_change(pos, inventory)
end


local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local inv = minetest.get_meta(pos):get_inventory()
	if listname == "recipe" then
		stack:set_count(1)
		inv:set_stack(listname, index, stack)
		after_recipe_change(pos, inv)
		return 0
	elseif listname == "output" then
		on_output_change(pos, inv, stack)
		return 0
	elseif listname == "src" and State:get_state(M(pos)) == tubelib.STANDBY then
		State:start(pos, M(pos))
	end
	return stack:get_count()
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
--		upgrade_autocrafter(pos)
	local inv = minetest.get_meta(pos):get_inventory()
	if listname == "recipe" then
		inv:set_stack(listname, index, ItemStack(""))
		after_recipe_change(pos, inv)
		return 0
	elseif listname == "output" then
		on_output_change(pos, inv, nil)
		return 0
	end
	return stack:get_count()
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local inv = minetest.get_meta(pos):get_inventory()
	local stack = inv:get_stack(from_list, from_index)

	if to_list == "output" then
		on_output_change(pos, inv, stack)
		return 0
	elseif from_list == "output" then
		on_output_change(pos, inv, nil)
		if to_list ~= "recipe" then
			return 0
		end -- else fall through to recipe list handling
	end

	if from_list == "recipe" or to_list == "recipe" then
		if from_list == "recipe" then
			inv:set_stack(from_list, from_index, ItemStack(""))
		end
		if to_list == "recipe" then
			stack:set_count(1)
			inv:set_stack(to_list, to_index, stack)
		end
		after_recipe_change(pos, inv)
		return 0
	end

	return count
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	State:state_button_event(pos, fields)
end


minetest.register_node("tubelib_addons1:autocrafter", {
	description = "Tubelib Autocrafter",
	drawtype = "normal",
	tiles = {
		'tubelib_front.png', 
		'tubelib_front.png', 
		'tubelib_addons1_autocrafter.png'},
	
	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons1:autocrafter")
		State:node_init(pos, number)
		local inv = M(pos):get_inventory()
		inv:set_size("src", 2*8)
		inv:set_size("recipe", 3*3)
		inv:set_size("dst", 3*3)
		inv:set_size("output", 1)
	end,
	
	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local inv = M(pos):get_inventory()
		return inv:is_empty("dst") and inv:is_empty("src")
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		autocrafterCache[minetest.hash_node_position(pos)] = nil
		tubelib.remove_node(pos)
		State:after_dig_node(pos, oldnode, oldmetadata, digger)
	end,
	
	on_rotate = screwdriver.disallow,
	on_timer = keep_running,
	on_receive_fields = on_receive_fields,
	
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,

	drop = "",
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("tubelib_addons1:autocrafter_active", {
	description = "Tubelib Autocrafter",
	drawtype = "normal",
	tiles = {
		'tubelib_front.png', 
		'tubelib_front.png', 
		{
			image = 'tubelib_addons1_autocrafter_active.png',
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 0.5,
			},
		},
	},
	
	on_rotate = screwdriver.disallow,
	on_timer = keep_running,
	on_receive_fields = on_receive_fields,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("tubelib_addons1:autocrafter_defect", {
	description = "Tubelib Autocrafter",
	drawtype = "normal",
	tiles = {
		'tubelib_front.png', 
		'tubelib_front.png',
		'tubelib_addons1_autocrafter.png^tubelib_defect.png'
	},
	
	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons1:autocrafter")
		State:node_init(pos, number)
		local meta = M(pos)
		local inv = meta:get_inventory()
		inv:set_size("src", 2*8)
		inv:set_size("recipe", 3*3)
		inv:set_size("dst", 3*3)
		inv:set_size("output", 1)
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
		autocrafterCache[minetest.hash_node_position(pos)] = nil
		tubelib.remove_node(pos)
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	output = "tubelib_addons1:autocrafter",
	recipe = {
		{"group:wood", 			"default:steel_ingot",  "group:wood"},
		{"tubelib:tubeS", 		"default:mese_crystal",	"tubelib:tubeS"},
		{"default:steel_ingot", "default:steel_ingot",  "default:steel_ingot"},
	},
})


tubelib.register_node("tubelib_addons1:autocrafter", 
	{"tubelib_addons1:autocrafter_active", "tubelib_addons1:autocrafter_defect"}, {
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
