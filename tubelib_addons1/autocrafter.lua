--[[

	Tubelib Addons
	==============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	The autocrafter is derived from pipeworks: 
	Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>  WTFPL

	autocrafter.lua:
	
]]--


local autocrafterCache = {}  -- caches some recipe data to avoid to call the slow function minetest.get_craft_result() every second

local SLEEP_CNT_START_VAL = 10

local craft_time = 2

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

local function get_item_info(stack)
	local name = stack:get_name()
	local def = minetest.registered_items[name]
	local description = def and def.description or "Unknown item"
	return description, name
end

local function get_craft(pos, inventory, hash)
	local hash = hash or minetest.hash_node_position(pos)
	local craft = autocrafterCache[hash]
	if not craft then
		local recipe = inventory:get_list("recipe")
		local output, decremented_input = minetest.get_craft_result({method = "normal", width = 3, items = recipe})
		craft = {recipe = recipe, consumption=count_index(recipe), output = output, decremented_input = decremented_input}
		autocrafterCache[hash] = craft
	end
	return craft
end

local function autocraft(inventory, craft)
	if not craft then return false end
	local output_item = craft.output.item

	-- check if we have enough room in dst
	if not inventory:room_for_item("dst", output_item) then	return false end
	local consumption = craft.consumption
	local inv_index = count_index(inventory:get_list("src"))
	-- check if we have enough material available
	for itemname, number in pairs(consumption) do
		if (not inv_index[itemname]) or inv_index[itemname] < number then return false end
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
	return true
end

local function formspec(state)
	return "size[8,9.2]"..		-- 9.2 is the max. for mobile devices
		"list[context;recipe;0,0;3,3;]"..
		"image[2.8,1;1,1;tubelib_gui_arrow.png]"..
		"list[context;output;3.5,1;1,1;]"..
		"image_button[3.5,2;1,1;".. tubelib.state_button(state) ..";button;]"..
		"list[context;src;0,3.2;8,2;]"..
		"list[context;dst;5,0;3,3;]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[current_player;main;0,5.4;8,4;]" ..
		"listring[current_player;main]"..
		"listring[context;src]" ..
		"listring[current_player;main]"..
		"listring[context;dst]" ..
		"listring[current_player;main]"
end

local function start_crafter(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	meta:set_int("running", SLEEP_CNT_START_VAL)
	meta:set_string("formspec",formspec(tubelib.RUNNING))
	node.name = "tubelib_addons1:autocrafter_active"
	minetest.swap_node(pos, node)
	local timer = minetest.get_node_timer(pos)
	if not timer:is_started() then
		timer:start(craft_time)
	end
	return false
end

local function stop_crafter(pos)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number") or ""
	meta:set_int("running", 0)
	meta:set_string("formspec",formspec(tubelib.STOPPED))
	meta:set_string("infotext", "Tubelib Autocrafter "..number..": stopped")
	node.name = "tubelib_addons1:autocrafter"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):stop()
	return false
end

local function goto_sleep(pos)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number") or ""
	meta:set_int("running", -1)
	meta:set_string("formspec",formspec(tubelib.STANDBY))
	meta:set_string("infotext", "Tubelib Autocrafter "..number..": standby")
	node.name = "tubelib_addons1:autocrafter"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):start(craft_time*SLEEP_CNT_START_VAL)
	return false
end

-- returns false to stop the timer, true to continue running
-- is started only from start_autocrafter(pos) after sanity checks and cached recipe
local function run_autocrafter(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local running = meta:get_int("running") - 1
	local inventory = meta:get_inventory()
	local craft = get_craft(pos, inventory)
	local output_item = craft.output.item
	
	-- only use crafts that have an actual result
	if output_item:is_empty() then
		if running <= 0 then
			return goto_sleep(pos)
		end
		meta:set_int("running", running)
		return true
	end

	if not autocraft(inventory, craft) then
		if running <= 0 then
			return goto_sleep(pos)
		end
		meta:set_int("running", running)
		return true
	end
	
	meta:set_int("item_counter", meta:get_int("item_counter") + output_item:get_count())
	
	if running <= 0 then
		return start_crafter(pos)
	else
		running = SLEEP_CNT_START_VAL
	end
	meta:set_int("running", running)
	return true
end

-- note, that this function assumes allready being updated to virtual items
-- and doesn't handle recipes with stacksizes > 1
local function after_recipe_change(pos, inventory)
	local meta = minetest.get_meta(pos)
	-- if we emptied the grid, there's no point in keeping it running or cached
	if inventory:is_empty("recipe") then
		minetest.get_node_timer(pos):stop()
		autocrafterCache[minetest.hash_node_position(pos)] = nil
		local number = meta:get_string("number")
		meta:set_string("infotext", "unconfigured Autocrafter: "..number)
		inventory:set_stack("output", 1, "")
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
	local description, name = get_item_info(output_item)
	local number = meta:get_string("number")
	meta:set_string("infotext", string.format("'%s' Tubelib Autocrafter "..number.."(%s)", description, name))
	inventory:set_stack("output", 1, output_item)
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



-- returns false if we shouldn't bother attempting to start the timer again after this
local function update_meta(meta, state)
	-- toggling the button doesn't quite call for running a recipe change check
	-- so instead we run a minimal version for infotext setting only
	-- this might be more written code, but actually executes less
	local number = meta:get_string("number")
	local output = meta:get_inventory():get_stack("output", 1)
	if output:is_empty() then -- doesn't matter if paused or not
		meta:set_string("infotext", "unconfigured Autocrafter "..number)
		meta:set_string("formspec",formspec(tubelib.STOPPED))
		return false
	end	
	
	local infotext
	local description, name = get_item_info(output)
	if state == tubelib.RUNNING then
		infotext = string.format("'%s' Autocrafter %s (%s)", description, number, name)
	else
		infotext = string.format("stopped '%s' Autocrafter %s", description, number)
	end
	meta:set_string("infotext", infotext)
	meta:set_string("formspec",formspec(state))
	return state == tubelib.RUNNING
end

local function on_receive_fields(pos, formname, fields, sender)
	if minetest.is_protected(pos, sender:get_player_name()) then
		return
	end
	local meta = minetest.get_meta(pos)
	local running = meta:get_int("running")
	if fields.button ~= nil then
		if running > 0 then
			update_meta(meta, tubelib.STOPPED)
			stop_crafter(pos)
			meta:set_int("running", 0)
		else
			if update_meta(meta, tubelib.RUNNING) then
				meta:set_int("running", 1)
				start_crafter(pos)
			else
				stop_crafter(pos)
				meta:set_int("running", 0)
			end
		end
	end
end


minetest.register_node("tubelib_addons1:autocrafter", {
	description = "Autocrafter",
	drawtype = "normal",
	tiles = {'tubelib_front.png', 'tubelib_addons1_autocrafter.png'},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local number = tubelib.add_node(pos, "tubelib_addons1:autocrafter")
		local inv = meta:get_inventory()
		inv:set_size("src", 2*8)
		inv:set_size("recipe", 3*3)
		inv:set_size("dst", 3*3)
		inv:set_size("output", 1)
		meta:set_string("number", number)
		meta:set_int("running", 0)
		meta:set_int("item_counter", 0)
		update_meta(meta, tubelib.STOPPED)
	end,
	
	on_receive_fields = on_receive_fields,
	
	can_dig = function(pos, player)
		--upgrade_autocrafter(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return (inv:is_empty("src") and inv:is_empty("dst"))
	end,
	
	on_destruct = function(pos)
		autocrafterCache[minetest.hash_node_position(pos)] = nil
		tubelib.remove_node(pos)
	end,
	
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	on_timer = run_autocrafter,

	paramtype = "light",
	sunlight_propagates = true,
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("tubelib_addons1:autocrafter_active", {
	description = "Autocrafter",
	drawtype = "normal",
	tiles = {
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
	
	on_receive_fields = on_receive_fields,
	
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	on_timer = run_autocrafter,

	paramtype = "light",
	sunlight_propagates = true,
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	output = "tubelib_addons1:autocrafter",
	recipe = {
		{"group:wood", 			"default:steel_ingot",  "group:wood"},
		{"tubelib:tube1", 		"default:mese_crystal",	"tubelib:tube1"},
		{"default:steel_ingot", "default:steel_ingot",  "default:steel_ingot"},
	},
})


tubelib.register_node("tubelib_addons1:autocrafter", {"tubelib_addons1:autocrafter_active"}, {
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
			return start_crafter(pos)
		elseif topic == "off" then
			return stop_crafter(pos)
		elseif topic == "state" then
			local meta = minetest.get_meta(pos)
			local running = meta:get_int("running")
			return tubelib.statestring(running)
		elseif topic == "counter" then
			local meta = minetest.get_meta(pos)
			return meta:get_int("item_counter")
		elseif topic == "clear_counter" then
			local meta = minetest.get_meta(pos)
			return meta:set_int("item_counter", 0)
		else
			return "unsupported"
		end
	end,
})	
