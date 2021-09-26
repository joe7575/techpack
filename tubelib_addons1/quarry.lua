--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	quarry.lua
	
	Quarry machine to dig stones and other ground blocks.
	
	The Quarry digs a hole 5x5 blocks large and up to 100 blocks deep.
	It starts at the given level (0 is same level as the quarry block,
	1 is one level higher and so on)) and goes down to the given depth number.
	It digs one block every 4 seconds.
	It requires one item Bio Fuel per 16 blocks.

]]--

-- Load support for I18n
local S = tubelib_addons1.S

-- for lazy programmers
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

local CYCLE_TIME = 4
local BURNING_TIME = 16
local STANDBY_TICKS = 4
local COUNTDOWN_TICKS = 5

local Side2Facedir = {F=0, R=1, B=2, L=3, D=4, U=5}
local Depth2Idx = {[1]=1 ,[2]=2, [3]=3, [5]=4, [10]=5, [15]=6, [20]=7, [25]=8, [50]=9, [100]=10}
local Level2Idx = {[2]=1, [1]=2, [0]=3, [-1]=4, [-2]=5, [-3]=6, 
				   [-5]=7, [-10]=8, [-15]=9, [-20]=10}

local function formspec(self, pos, meta)
	local depth = meta:get_int("max_levels")
	if not Depth2Idx[depth] then depth = 1 end
	local start_level = meta:get_int("start_level")
	if not Level2Idx[start_level] then start_level = 0 end
	local endless = meta:get_int("endless") or 0
	local fuel = meta:get_int("fuel") or 0
	-- some recalculations
	endless = endless == 1 and "true" or "false"
	if self:get_state(meta) ~= tubelib.RUNNING then
		fuel = fuel * 100/BURNING_TIME
	else
		fuel = 0
	end
	
	return "size[9,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"dropdown[0,0;1.5;level;2,1,0,-1,-2,-3,-5,-10,-15,-20;"..Level2Idx[start_level].."]".. 
	"label[1.6,0.2;"..S("Start level").."]"..
	"dropdown[0,1;1.5;depth;1,2,3,5,10,15,20,25,50,100;"..Depth2Idx[depth].."]".. 
	"label[1.6,1.2;"..S("Digging depth").."]"..
	"checkbox[0,2;endless;"..S("Run endless")..";"..endless.."]"..
	"list[context;main;5,0;4,4;]"..
	"list[context;fuel;1.5,3;1,1;]"..
	"item_image[1.5,3;1,1;tubelib_addons1:biofuel]"..
	"image[2.5,3;1,1;default_furnace_fire_bg.png^[lowpart:"..
	fuel..":default_furnace_fire_fg.png]"..
	"image_button[3.5,3;1,1;".. self:get_state_button_image(meta) ..";state_button;]"..
	"list[current_player;main;0.5,4.3;8,4;]"..
	"listring[context;main]"..
	"listring[current_player;main]"
end

local State = tubelib.NodeStates:new({
	node_name_passive = "tubelib_addons1:quarry",
	node_name_active = "tubelib_addons1:quarry_active",
	node_name_defect = "tubelib_addons1:quarry_defect",
	infotext_name = S("Tubelib Quarry"),
	cycle_time = CYCLE_TIME,
	standby_ticks = STANDBY_TICKS,
	has_item_meter = true,
	aging_factor = 12,
	on_stop = function(pos, meta, oldstate)
		if oldstate == tubelib.RUNNING then
			meta:set_int("idx", 1) -- restart from the beginning
			meta:set_string("quarry_pos", nil)
		end
	end,
	formspec_func = formspec,
})

local function get_pos(pos, facedir, side, steps)
	facedir = (facedir + Side2Facedir[side]) % 4
	local dir = vector.multiply(minetest.facedir_to_dir(facedir), steps or 1)
	return vector.add(pos, dir)
end	

local function get_node_lvm(pos)
	local node = minetest.get_node_or_nil(pos)
	if node then
		return node
	end
	local vm = minetest.get_voxel_manip()
	local MinEdge, MaxEdge = vm:read_from_map(pos, pos)
	local data = vm:get_data()
	local param2_data = vm:get_param2_data()
	local area = VoxelArea:new({MinEdge = MinEdge, MaxEdge = MaxEdge})
	local idx = area:index(pos.x, pos.y, pos.z)
	node = {
		name = minetest.get_name_from_content_id(data[idx]),
		param2 = param2_data[idx]
	}
	return node
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local inv = M(pos):get_inventory()
	if listname == "main" then
		return stack:get_count()
	elseif listname == "fuel" and tubelib.is_fuel(stack) then
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


local QuarrySchedule = {0,0,3,3,3,3,2,2,2,2,1,1,1,1,0,3,0,0,3,3,2,2,1,0,0}


local function get_next_pos(pos, facedir, dir)
	facedir = (facedir + dir) % 4
	return vector.add(pos, core.facedir_to_dir(facedir))
end

local function skip_the_air(pos, curr_level, facedir) 
	local pos1, pos2, lPos
	pos1 = get_pos(pos, facedir, "F", 2)
	pos2 = get_pos(pos, facedir, "B", 2)
	pos2 = get_pos(pos2, facedir, "L", 5)
	pos1.y = curr_level
	pos2.y = curr_level
	while true do
		lPos = minetest.find_nodes_in_area(pos1, pos2, {"air"})
		if #lPos ~= 25 then break end
		pos1.y = pos1.y - 1
		pos2.y = pos2.y - 1
	end
	return pos2.y 
end
	
local function quarry_next_node(pos, meta)
	-- check fuel
	local fuel = meta:get_int("fuel") or 0
	if fuel <= 0 then
		local fuel_item = tubelib.get_this_item(meta, "fuel", 1)
		if fuel_item == nil then
			State:fault(pos, meta)
			return
		end
		if not tubelib.is_fuel(fuel_item) then
			State:fault(pos, meta)
			tubelib.put_item(meta, "fuel", fuel_item)
			return
		end
		fuel = BURNING_TIME
	else
		fuel = fuel - 1
	end
	meta:set_int("fuel", fuel) 
	
	local idx = meta:get_int("idx")
	if idx == 0 then idx = 1 end
	local facedir = minetest.get_node(pos).param2
	local owner = meta:get_string("owner")
	local endless = meta:get_int("endless")
	local start_y = pos.y + meta:get_int("start_level")
	local stop_y = pos.y + meta:get_int("start_level") - meta:get_int("max_levels") + 1
	local quarry_pos = P(meta:get_string("quarry_pos"))
	
	if quarry_pos == nil then  -- start at the beginning?
		quarry_pos = get_pos(pos, facedir, "L")
		local y = skip_the_air(quarry_pos, start_y, facedir) 
		if y < stop_y then -- below the base line?
			meta:set_int("idx", 1)
			meta:set_string("quarry_pos", nil)
			State:stop(pos, meta)
			return
		end
		quarry_pos.y = y
	elseif idx < #QuarrySchedule then
		quarry_pos = get_next_pos(quarry_pos, facedir, QuarrySchedule[idx])
		idx = idx + 1
	elseif quarry_pos.y > stop_y then
		local y = quarry_pos.y
		quarry_pos = get_pos(pos, facedir, "L")
		quarry_pos.y = y - 1
		idx = 1
	elseif endless == 1 then  -- farming mode
		quarry_pos = get_pos(pos, facedir, "L")
		quarry_pos.y = start_y
		idx = 1
	else
		meta:set_int("idx", 1)
		meta:set_string("quarry_pos", nil)
		State:stop(pos, meta)
		return
	end
	meta:set_int("idx", idx)
	meta:set_string("quarry_pos", P2S(quarry_pos))

	if minetest.is_protected(quarry_pos, owner) then
		minetest.chat_send_player(owner, S("[Tubelib Quarry] Area is protected!") ..
		  " " .. minetest.pos_to_string(quarry_pos) )
		State:fault(pos, meta)
		return
	end

	local node = get_node_lvm(quarry_pos)
	if node then
		local number = meta:get_string("tubelib_number")
		local order = tubelib_addons1.GroundNodes[node.name]
		if order ~= nil then
			local inv = meta:get_inventory()
			if inv:room_for_item("main", ItemStack(order.drop)) then
				minetest.remove_node(quarry_pos)
				inv:add_item("main", ItemStack(order.drop))
				meta:set_string("infotext", S("Tubelib Quarry").." "..number..
						": "..S("running").." "..idx.."/"..(start_y-quarry_pos.y+1))
				State:keep_running(pos, meta, COUNTDOWN_TICKS, 1)
			else
				State:blocked(pos, meta)
			end
		else
			meta:set_string("infotext", S("Tubelib Quarry").." "..number..
					": "..S("running").." "..idx.."/"..(start_y-quarry_pos.y+1))
		end
	end
end

local function keep_running(pos, elapsed)
	if tubelib.data_not_corrupted(pos) then
		local meta = M(pos)
		quarry_next_node(pos, meta)
		return State:is_active(meta)
	end
	return false
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local meta = M(pos)
	
	local max_levels = meta:get_int("max_levels")
	if fields.depth then
		max_levels = tonumber(fields.depth)
	end
	if max_levels ~= meta:get_int("max_levels") then
		meta:set_string("quarry_pos", nil)	-- reset the quarry
		meta:set_int("max_levels", max_levels)
		State:stop(pos, meta)
	end
	
	local start_level = meta:get_int("start_level") or 0
	if fields.level ~= nil then
		start_level = tonumber(fields.level)
	end
	if start_level ~= meta:get_int("start_level") then
		meta:set_string("quarry_pos", nil)	-- reset the quarry
		meta:set_int("start_level", start_level)
		State:stop(pos, meta)
	end
	
	local endless = meta:get_int("endless") or 0
	if fields.endless ~= nil then
		endless = fields.endless == "true" and 1 or 0
	end
	meta:set_int("endless", endless)
	
	State:state_button_event(pos, fields)
end

minetest.register_node("tubelib_addons1:quarry", {
	description = S("Tubelib Quarry"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_addons1_quarry.png',
		'tubelib_addons1_quarry.png',
		'tubelib_addons1_quarry_passive.png',
		'tubelib_addons1_quarry.png',
		'tubelib_addons1_quarry.png^[transformFX',
	},

	after_place_node = function(pos, placer)
		local meta = M(pos)
		local inv = meta:get_inventory()
		inv:set_size('main', 16)
		inv:set_size('fuel', 1)
		local number = tubelib.add_node(pos, "tubelib_addons1:quarry")
		meta:set_string("owner", placer:get_player_name())
		meta:set_int("endless", 0)
		meta:set_int("curr_level", -1)
		meta:set_int("max_levels", 1)
		State:node_init(pos, number)
	end,

	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local inv = M(pos):get_inventory()
		return inv:is_empty("main")
	end,

	on_dig = function(pos, node, player)
		State:on_dig_node(pos, node, player)
		tubelib.remove_node(pos)
	end,
	
	on_rotate = screwdriver.disallow,
	on_receive_fields = on_receive_fields,
	on_timer = keep_running,
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
	description = S("Tubelib Quarry"),
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

	diggable = false,
	can_dig = function() return false end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("tubelib_addons1:quarry_defect", {
	description = S("Tubelib Quarry"),
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_addons1_quarry.png^tubelib_defect.png',
		'tubelib_addons1_quarry_passive.png^tubelib_defect.png',
		'tubelib_addons1_quarry.png^tubelib_defect.png',
		'tubelib_addons1_quarry.png^[transformFX^tubelib_defect.png',
	},

	after_place_node = function(pos, placer)
		local meta = M(pos)
		local inv = meta:get_inventory()
		inv:set_size('main', 16)
		inv:set_size('fuel', 1)
		local number = tubelib.add_node(pos, "tubelib_addons1:quarry")
		meta:set_string("owner", placer:get_player_name())
		meta:set_int("endless", 0)
		meta:set_int("curr_level", -1)
		meta:set_int("max_levels", 1)
		State:node_init(pos, number)
		State:defect(pos, M(pos))
	end,

	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		local inv = M(pos):get_inventory()
		return inv:is_empty("main") and inv:is_empty("fuel")
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		tubelib.remove_node(pos)
	end,

	on_rotate = screwdriver.disallow,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	output = "tubelib_addons1:quarry",
	recipe = {
		{"group:wood", 			"default:mese_crystal", "group:wood"},
		{"default:steel_ingot", "default:mese_crystal",	"tubelib:tubeS"},
		{"group:wood", 			"default:mese_crystal", "group:wood"},
	},
})


tubelib.register_node("tubelib_addons1:quarry", 
	{"tubelib_addons1:quarry_active", "tubelib_addons1:quarry_defect"}, {
	invalid_sides = {"L"},
	on_pull_item = function(pos, side)
		return tubelib.get_item(M(pos), "main")
	end,
	on_push_item = function(pos, side, item)
		if not tubelib.is_fuel(item) then
			return false
		end
		return tubelib.put_item(M(pos), "fuel", item)
	end,
	on_unpull_item = function(pos, side, item)
		return tubelib.put_item(M(pos), "main", item)
	end,
	on_recv_message = function(pos, topic, payload)
		if topic == "fuel" then
			return tubelib.fuelstate(M(pos), "fuel")
		end
		
		local resp = State:on_receive_message(pos, topic, payload)
		if resp then
			return resp
		else
			return "unsupported"
		end
	end,
	on_node_load = function(pos)
		local depth = M(pos):get_int("max_levels") or 1
		-- If depth is 1, it is likely that the quarry is used as cobble generator,
		-- controlled by a sequencer. If so, don't restart the timer.
		State:on_node_load(pos, depth == 1)
	end,
	on_node_repair = function(pos)
		return State:on_node_repair(pos)
	end,
})	

