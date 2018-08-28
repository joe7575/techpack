--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017,2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	quarry.lua
	
	Quarry machine to dig stones and other ground blocks.
	
	The Quarry digs a hole 5x5 blocks large and up to 25 blocks deep.
	It starts at the given level (0 is same level as the quarry block,
	1 is one level higher and so on)) and goes down to the given depth number.
	It digs one block every 4 seconds.
	It requires one item Bio Fuel per 16 blocks.

]]--

local CYCLE_TIME = 4
local BURNING_TIME = 16
local TICKS_TO_SLEEP = 5
local STOP_STATE = 0
local FAULT_STATE = -3

local Depth2Idx = {[1]=1 ,[2]=2, [3]=3, [5]=4, [10]=5, [15]=6, [20]=7, [25]=8}
local Level2Idx = {[2]=1, [1]=2, [0]=3, [-1]=4, [-2]=5, [-3]=6, 
				   [-5]=7, [-10]=8, [-15]=9, [-20]=10}

local function quarry_formspec(meta, state)
	local depth = meta:get_int("max_levels") or 1
	local start_level = meta:get_int("start_level") or 1
	local endless = meta:get_int("endless") or 0
	local fuel = meta:get_int("fuel") or 0
	-- some recalculations
	endless = endless == 1 and "true" or "false"
	if state == tubelib.RUNNING then
		fuel = fuel * 100/BURNING_TIME
	else
		fuel = 0
	end
	
	return "size[9,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"dropdown[0,0;1.5;level;2,1,0,-1,-2,-3,-5,-10,-15,-20;"..Level2Idx[start_level].."]".. 
	"label[1.6,0.2;Start level]"..
	"dropdown[0,1;1.5;depth;1,2,3,5,10,15,20,25;"..Depth2Idx[depth].."]".. 
	"label[1.6,1.2;Digging depth]"..
	"checkbox[0,2;endless;Run endless;"..endless.."]"..
	"list[context;main;5,0;4,4;]"..
	"list[context;fuel;1.5,3;1,1;]"..
	"item_image[1.5,3;1,1;tubelib_addons1:biofuel]"..
	"image[2.5,3;1,1;default_furnace_fire_bg.png^[lowpart:"..
	fuel..":default_furnace_fire_fg.png]"..
	"image_button[3.5,3;1,1;".. tubelib.state_button(state) ..";button;]"..
	"list[current_player;main;0.5,4.3;8,4;]"..
	"listring[context;main]"..
	"listring[current_player;main]"
end

local function get_pos(pos, facedir, side)
	local offs = {F=0, R=1, B=2, L=3, D=4, U=5}
	local dst_pos = table.copy(pos)
	facedir = (facedir + offs[side]) % 4
	local dir = minetest.facedir_to_dir(facedir)
	return vector.add(dst_pos, dir)
end	

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if listname == "main" then
		return stack:get_count()
	elseif listname == "fuel" and stack:get_name() == "tubelib_addons1:biofuel" then
		return stack:get_count()
	end
	return 0
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function start_the_machine(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local number = meta:get_string("number")
	meta:set_int("running", TICKS_TO_SLEEP)
	meta:set_string("infotext", "Tubelib Quarry "..number..": running")
	meta:set_string("formspec", quarry_formspec(meta, tubelib.RUNNING))
	node.name = "tubelib_addons1:quarry_active"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):start(CYCLE_TIME)
	return false
end

local function stop_the_machine(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local number = meta:get_string("number")
	meta:set_int("running", STOP_STATE)
	meta:set_int("idx", 1) -- restart from the beginning
	meta:set_string("quarry_pos", nil)
	meta:set_string("infotext", "Tubelib Quarry "..number..": stopped")
	meta:set_string("formspec", quarry_formspec(meta, tubelib.STOPPED))
	node.name = "tubelib_addons1:quarry"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):stop()
	return false
end

local function goto_fault(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local number = meta:get_string("number")
	meta:set_int("running", FAULT_STATE)
	meta:set_string("infotext", "Tubelib Quarry "..number..": fault")
	meta:set_string("formspec", quarry_formspec(meta, tubelib.FAULT))
	node.name = "tubelib_addons1:quarry"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):stop()
	return false
end

local QuarrySchedule = {0,0,3,3,3,3,2,2,2,2,1,1,1,1,0,3,0,0,3,3,2,2,1,0,0}


local function get_next_pos(pos, facedir, dir)
	facedir = (facedir + dir) % 4
	return vector.add(pos, core.facedir_to_dir(facedir))
end

local function quarry_next_node(pos, meta)
	local idx = meta:get_int("idx")
	local facedir = meta:get_int("facedir")
	local owner = meta:get_string("owner")
	local endless = meta:get_int("endless")
	local curr_level = meta:get_int("curr_level")
	local stop_level = pos.y + meta:get_int("start_level") 
							 - meta:get_int("max_levels") 
							 + 1
	
	local quarry_pos = minetest.string_to_pos(meta:get_string("quarry_pos"))
	if quarry_pos == nil then
		curr_level = pos.y + meta:get_int("start_level")	-- start level
		quarry_pos = get_pos(pos, facedir, "L")
		quarry_pos.y = curr_level
		idx = 1
	elseif idx < #QuarrySchedule then
		quarry_pos = get_next_pos(quarry_pos, facedir, QuarrySchedule[idx])
		idx = idx + 1
	elseif curr_level > stop_level then
		curr_level = curr_level - 1
		quarry_pos = get_pos(pos, facedir, "L")
		quarry_pos.y = curr_level
		idx = 1
	elseif endless == 1 then  -- farming mode
		quarry_pos = get_pos(pos, facedir, "L")
		quarry_pos.y = pos.y + meta:get_int("start_level")	-- start level
		idx = 1
	else
		curr_level = pos.y + meta:get_int("start_level")	-- start level
		meta:set_int("idx", 1)
		meta:set_string("quarry_pos", nil)
		return false		-- stopped
	end
	meta:set_int("curr_level", curr_level)
	meta:set_int("idx", idx)
	meta:set_string("quarry_pos", minetest.pos_to_string(quarry_pos))

	if minetest.is_protected(quarry_pos, owner) then
		minetest.chat_send_player(owner, "[Tubelib Quarry] Area is protected!")
		return nil			-- fault
	end

	local node = minetest.get_node_or_nil(quarry_pos)
	if node == nil then
		return true
	end

	local number = meta:get_string("number")
	local order = tubelib_addons1.GroundNodes[node.name]
	if order ~= nil then
		local inv = meta:get_inventory()
		if inv:room_for_item("main", ItemStack(order.drop)) then
			minetest.remove_node(quarry_pos)
			inv:add_item("main", ItemStack(order.drop))
			meta:set_string("infotext", "Tubelib Quarry "..number..
					": running "..idx.."/"..(curr_level-pos.y))
			return true
		else
			return nil		-- fault
		end
	end
	meta:set_string("infotext", "Tubelib Quarry "..number..
			": running "..idx.."/"..(curr_level-pos.y))
	return true
end

local function keep_running(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local running = meta:get_int("running") - 1
	local fuel = meta:get_int("fuel") or 0
	local inv = meta:get_inventory()
	-- check fuel
	if fuel <= 0 then
		if tubelib.get_this_item(meta, "fuel", 1) == nil then
			return goto_fault(pos)
		end
		fuel = BURNING_TIME
	else
		fuel = fuel - 1
	end
	meta:set_int("fuel", fuel) 
	
	local busy = quarry_next_node(pos, meta)
	if busy == true then 
		if running <= STOP_STATE then
			return start_the_machine(pos)
		else
			running = TICKS_TO_SLEEP
		end
	elseif busy == nil then
		return goto_fault(pos)
	else
		return stop_the_machine(pos)
	end
	meta:set_int("running", running)
	meta:set_string("formspec", quarry_formspec(meta, tubelib.RUNNING))
	return true
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local meta = minetest.get_meta(pos)
	
	local max_levels = meta:get_int("max_levels")
	if fields.depth then
		max_levels = tonumber(fields.depth)
	end
	if max_levels ~= meta:get_int("max_levels") then
		meta:set_string("quarry_pos", nil)	-- reset the quarry
		stop_the_machine(pos)
		meta:set_int("max_levels", max_levels)
	end
	
	local start_level = meta:get_int("start_level") or 0
	if fields.level ~= nil then
		start_level = tonumber(fields.level)
	end
	if start_level ~= meta:get_int("start_level") then
		meta:set_string("quarry_pos", nil)	-- reset the quarry
		stop_the_machine(pos)
		meta:set_int("start_level", start_level)
	end
	
	local endless = meta:get_int("endless") or 0
	if fields.endless ~= nil then
		endless = fields.endless == "true" and 1 or 0
	end
	meta:set_int("endless", endless)
	
	local running = meta:get_int("running") or STOP_STATE
	if fields.button ~= nil then
		if running > STOP_STATE then
			stop_the_machine(pos)
		else
			start_the_machine(pos)
		end
	else
		meta:set_string("formspec", quarry_formspec(meta, tubelib.state(running)))
	end
end

minetest.register_node("tubelib_addons1:quarry", {
	description = "Tubelib Quarry",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_addons1_quarry.png',
		'tubelib_addons1_quarry.png',
		'tubelib_addons1_quarry_passive.png',
		'tubelib_addons1_quarry.png',
		'tubelib_addons1_quarry.png^[transformFX',
	},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size('main', 16)
		inv:set_size('fuel', 1)
	end,
	
	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib_addons1:quarry")
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Quarry "..number..": stopped")
		local facedir = minetest.dir_to_facedir(placer:get_look_dir(), false)
		meta:set_int("facedir", facedir)
		meta:set_string("number", number)
		meta:set_string("owner", placer:get_player_name())
		meta:set_int("running", STOP_STATE)
		meta:set_int("endless", 0)
		meta:set_int("curr_level", -1)
		meta:set_int("max_levels", 1)
		meta:set_string("formspec", quarry_formspec(meta, tubelib.STOPPED))
	end,

	on_receive_fields = on_receive_fields,
	on_rotate = screwdriver.disallow,

	on_dig = function(pos, node, puncher, pointed_thing)
		if minetest.is_protected(pos, puncher:get_player_name()) then
			return
		end
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if inv:is_empty("main") then
			minetest.node_dig(pos, node, puncher, pointed_thing)
			tubelib.remove_node(pos)
		end
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


minetest.register_node("tubelib_addons1:quarry_active", {
	description = "Tubelib Quarry",
	tiles = {
		-- up, down, right, left, back, front

		'tubelib_front.png',
		'tubelib_addons1_quarry.png',
		'tubelib_addons1_quarry.png',
		{
			image = 'tubelib_addons1_quarry_active.png',
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 2.0,
			},
		},
		'tubelib_addons1_quarry.png',
		'tubelib_addons1_quarry.png^[transformFX',
	},

	on_receive_fields = on_receive_fields,

	on_timer = keep_running,
	on_rotate = screwdriver.disallow,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	output = "tubelib_addons1:quarry",
	recipe = {
		{"group:wood", 			"default:mese_crystal", "group:wood"},
		{"default:steel_ingot", "default:mese_crystal",	"tubelib:tube1"},
		{"group:wood", 			"default:mese_crystal", "group:wood"},
	},
})


tubelib.register_node("tubelib_addons1:quarry", {"tubelib_addons1:quarry_active"}, {
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		return tubelib.get_item(meta, "main")
	end,
	on_push_item = function(pos, side, item)
		if item:get_name() == "tubelib_addons1:biofuel" then
			local meta = minetest.get_meta(pos)
			return tubelib.put_item(meta, "fuel", item)
		end
		return false
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
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
		elseif topic == "fuel" then
			local meta = minetest.get_meta(pos)
			return tubelib.fuelstate(meta, "fuel")
		else
			return "unsupported"
		end
	end,
})	

