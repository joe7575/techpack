--[[

	TechPack Warehouse
	==================

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	common.lua

]]--

--- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

local STANDBY_TICKS = 4
local COUNTDOWN_TICKS = 2
local CYCLE_TIME = 2


local Cache = {}

techpack_warehouse.Box = {}
techpack_warehouse.Turn180 = {F="B", L="R", B="F", R="L", U="D", D="U"}

local function formspec(self, pos, meta)
	return "size[10,9]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"image_button[0,0;1,1;techpack_warehouse_arrow_inv.png;shift;;true;false;]"..
	"list[context;shift;1,0;7,1;]"..
	"image_button[9,0;1,1;techpack_warehouse_arrow_inv.png;shift;;true;false;]"..
	"image_button[8,0;1,1;".. self:get_state_button_image(meta) ..";state_button;]"..
	
	"image_button[0,1.4;1,1;techpack_warehouse_filter_inv.png;filter;;true;false;]"..
	"list[context;filter;1,1.4;8,1;]"..
	"image_button[9,1.4;1,1;techpack_warehouse_filter_inv.png;filter;;true;false;]"..
	
	"image_button[0,2.5;1,1;techpack_warehouse_inventory_inv.png;storage;;true;false;]"..
	"list[context;main;1,2.5;8,1;]"..
	"image_button[9,2.5;1,1;techpack_warehouse_inventory_inv.png;storage;;true;false;]"..
	
	"image_button[0,3.6;1,1;techpack_warehouse_input_inv.png;input;;true;false;]"..
	"list[context;input;1,3.6;8,1;]"..
	"image_button[9,3.6;1,1;techpack_warehouse_input_inv.png;input;;true;false;]"..
	
	"tooltip[shift;Pass-through storage for unconfigured items (turn on/off)]"..
	"tooltip[filter;Filter: To configure the 8 storages]"..
	"tooltip[storage;Storage: All items will be stored here]"..
	"tooltip[input;Input: Put items will be moved to the storage, if configured]"..
	
	"list[current_player;main;1,5.3;8,4;]"..
	"listring[context;shift]"..
	"listring[current_player;main]"..
	"listring[context;input]"
end

local function move_to_main(pos, index)
	local inv = M(pos):get_inventory()
	local main_stack = inv:get_stack("main", index)
	local inp_stack = inv:get_stack("input", index)
	
	if inp_stack:get_name() ~= "" then
		local stack = ItemStack(inp_stack:get_name())
		stack:set_count(inp_stack:get_count() + main_stack:get_count())
		inp_stack:clear()
		
		inv:set_stack("main", index, stack)
		inv:set_stack("input", index, inp_stack)
	end
end

local function move_to_player_inv(player_name, pos, main_stack, index)
	local player_inv = minetest.get_inventory({type="player", name=player_name})
	local num = main_stack:get_count()
	if num > 99 then
		num = 99
	end
	local leftover = player_inv:add_item("main", ItemStack(main_stack:get_name().." "..num))
	main_stack:set_count(main_stack:get_count() - num + leftover:get_count())
	local node_inv = M(pos):get_inventory()	
	node_inv:set_stack("main", index, main_stack)
end

function techpack_warehouse.tiles(background_img)
	return {
		-- up, down, right, left, back, front
		'tubelib_pusher1.png^tubelib_addons3_node_frame4.png',
		'tubelib_pusher1.png^tubelib_addons3_node_frame4.png',
		background_img..'^techpack_warehouse_box_side.png',
		background_img..'^techpack_warehouse_box_side.png',
		background_img..'^techpack_warehouse_box_back.png',
		background_img..'^techpack_warehouse_box_front.png',
	}
end

function techpack_warehouse.tiles_active(background_img)
	return {
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
		background_img..'^techpack_warehouse_box_side.png',
		background_img..'^techpack_warehouse_box_side.png',
		background_img..'^techpack_warehouse_box_back.png',
		background_img..'^techpack_warehouse_box_front.png',
	}
end

function techpack_warehouse.tiles_defect(background_img)
	return {
		-- up, down, right, left, back, front
		'tubelib_pusher1.png^tubelib_addons3_node_frame4.png',
		'tubelib_pusher1.png^tubelib_addons3_node_frame4.png',
		background_img..'^techpack_warehouse_box_side.png^tubelib_defect.png',
		background_img..'^techpack_warehouse_box_side.png^tubelib_defect.png',
		background_img..'^techpack_warehouse_box_back.png^tubelib_defect.png',
		background_img..'^techpack_warehouse_box_front.png^tubelib_defect.png',
	}
end



function techpack_warehouse.Box:new(attr)
	local o = {
		node_name = attr.node_name,
		description = attr.description,
		inv_size = attr.inv_size,
		background_img = attr.background_img,
	}
	o.State = tubelib.NodeStates:new({
		node_name_passive = attr.node_name,
		node_name_active = attr.node_name.."_active",
		node_name_defect = attr.node_name.."_defect",
		infotext_name = attr.description,
		cycle_time = CYCLE_TIME,
		standby_ticks = STANDBY_TICKS,
		has_item_meter = true,
		aging_factor = 50,
		formspec_func = formspec,
	})
	setmetatable(o, self)
	self.__index = self
	return o
end

function techpack_warehouse.numbers_to_shift(self, meta, item)
	-- check cache
	local number = meta:get_string("tubelib_number")
	local item_name = item:get_name()
	if not Cache[number] then
		local inv = meta:get_inventory()
		Cache[number] = {}
		for idx,items in ipairs(inv:get_list("filter")) do
			Cache[number][idx] = items:get_name()
		end
	end
	
	-- determine number to shift
	local num_items = item:get_count()
	local inv_size = meta:get_int("inv_size")
	local inv = meta:get_inventory()
	
	for idx, name in ipairs(Cache[number]) do
		if item_name == name then
			local stack_size = inv:get_stack("main", idx):get_count()
			if stack_size == self.inv_size then -- full?
				Cache[number][idx] = "" -- delete for searching
			elseif (stack_size + num_items) > self.inv_size then -- limit will be reached?
				inv:set_stack("main", idx, ItemStack({name = item_name, count = self.inv_size}))
				Cache[number][idx] = "" -- delete for searching
				-- search with the rest for further slots
				num_items = num_items - (self.inv_size - stack_size)
			else
				inv:set_stack("main", idx, ItemStack({name = item_name, count = stack_size + num_items}))
				return 0
			end
		end
	end
	return num_items
end

function techpack_warehouse.allow_metadata_inventory_put(self, pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local inv = M(pos):get_inventory()
	local main_stack = inv:get_stack("main", index)
	local item_name = inv:get_stack("filter", index):get_name()
	if listname == "input" and item_name == stack:get_name() then
		return math.min(stack:get_count(), self.inv_size - main_stack:get_count())
	elseif listname == "filter" and item_name == main_stack:get_name() then
		local number = M(pos):get_string("tubelib_number")
		Cache[number] = nil
		return 1
	elseif listname == "shift" then
		return stack:get_count()
	end
	return 0
end

function techpack_warehouse.on_metadata_inventory_put(pos, listname, index, stack, player)
	if listname == "input" then
		local number = M(pos):get_string("tubelib_number")
		Cache[number] = nil
		minetest.after(0.5, move_to_main, pos, index)
	end
end

function techpack_warehouse.allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local inv = M(pos):get_inventory()
	local main_stack = inv:get_stack("main", index)
	local number = M(pos):get_string("tubelib_number")
	if listname == "main" then
		Cache[number] = nil
		minetest.after(0.1, move_to_player_inv, player:get_player_name(), pos, main_stack, index)
		return 0
	elseif listname == "filter" and main_stack:is_empty() then
		Cache[number] = nil
		return 1
	elseif listname == "shift" then
		Cache[number] = nil
		return stack:get_count()
	end
	return 0
end

function techpack_warehouse.allow_metadata_inventory_move(pos, listname, index, stack, player)
	return 0
end

function techpack_warehouse.on_receive_fields(self, pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local number = M(pos):get_string("tubelib_number")
	Cache[number] = nil
	self.State:state_button_event(pos, fields)
end

function techpack_warehouse.after_place_node(self, pos, placer, itemstack)
	local meta = M(pos)
	local number = tubelib.add_node(pos, self.node_name)
	self.State:node_init(pos, number)
	meta:set_string("player_name", placer:get_player_name())
	local inv = meta:get_inventory()
	inv:set_size('shift', 7)
	inv:set_size('filter', 8)
	inv:set_size('main', 8)
	inv:set_size('input', 8)
end
		
function techpack_warehouse.on_timer(self, pos, elapsed)
	if tubelib.data_not_corrupted(pos) then
		local meta = M(pos)
		local inv = meta:get_inventory()
		if not inv:is_empty("shift") then
			--local number = meta:get_string("tubelib_number")
			local player_name = meta:get_string("player_name")
			local offs = meta:get_int("offs")
			local push_dir = meta:get_string("push_dir")
			if push_dir == "" then push_dir = "L" end
			meta:set_int("offs", offs + 1)
			for i = 0,7 do
				local idx = ((i + offs) % 8) + 1
				local stack = inv:get_stack("shift", idx)
				if stack:get_count() > 0 then
					if tubelib.push_items(pos, push_dir, stack, player_name) then
						-- The effort is needed here for the case the 
						-- pusher pushes into its own chest.
						local num = stack:get_count()
						stack = inv:get_stack("shift", idx)
						stack:take_item(num)
						inv:set_stack("shift", idx, stack)
						self.State:keep_running(pos, meta, COUNTDOWN_TICKS)
						break
					else
						self.State:blocked(pos, meta)
					end
				end
			end
		else
			self.State:idle(pos, meta)
		end
		
		return self.State:is_active(meta)
	end
	return false
end
	
function techpack_warehouse.can_dig(self, pos)
	local inv = M(pos):get_inventory()
	return inv:is_empty("main") and inv:is_empty("shift")
end

function techpack_warehouse.after_dig_node(self, pos, oldnode, oldmetadata, digger)
	tubelib.remove_node(pos)
	if oldnode.name == self.node_name then -- not for defect nodes
		self.State:after_dig_node(pos, oldnode, oldmetadata, digger)
	end
end

function techpack_warehouse.get_num_items(meta, index)
	index = index and tonumber(index)
	if index < 1 then index = 1 end
	if index > 8 then index = 8 end
	local inv = meta:get_inventory()
	return inv:get_stack("main", index):get_count()
end