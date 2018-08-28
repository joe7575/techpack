--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017,2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	liquidsampler.lua
	
]]--

local CYCLE_TIME = 8

local function get_pos(pos, facedir, side)
	local offs = {F=0, R=1, B=2, L=3, D=4, U=5}
	local dst_pos = table.copy(pos)
	facedir = (facedir + offs[side]) % 4
	local dir = minetest.facedir_to_dir(facedir)
	return vector.add(dst_pos, dir)
end	


local function test_liquid(node)
	local liquiddef = bucket.liquids[node.name]
	if liquiddef ~= nil	and liquiddef.itemname ~= nil and 
			node.name == liquiddef.source then
		return liquiddef.itemname
	end
end

local function sample_liquid(pos, meta)
	local giving_back = test_liquid(minetest.get_node(pos))
	if giving_back then
		local inv = meta:get_inventory()
		if inv:room_for_item("dst", ItemStack(giving_back)) and
				inv:contains_item("src", ItemStack("bucket:bucket_empty")) then
			minetest.remove_node(pos)
			inv:remove_item("src", ItemStack("bucket:bucket_empty"))
			inv:add_item("dst", ItemStack(giving_back))
			return true		-- success
		else
			return nil		-- standby
		end
	else
		return false		-- fault
	end
end

local function formspec(meta, state)
	return "size[9,8.5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;src;0,0;1,4;]"..
	"image[0,0;1,1;bucket.png]"..
	"image[1,1;1,1;tubelib_gui_arrow.png]"..
	"image_button[1,3;1,1;".. tubelib.state_button(state) ..";button;]"..
	"list[context;dst;2,0;7,4;]"..
	"list[current_player;main;0.5,4.5;8,4;]"..
	"listring[current_player;main]"..
	"listring[context;src]" ..
	"listring[current_player;main]"..
	"listring[context;dst]" ..
	"listring[current_player;main]"
end

local function switch_on(pos, node)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", tubelib.STATE_RUNNING)
	meta:set_string("infotext", "Liquid Sampler "..number..": running")
	meta:set_string("formspec", formspec(meta, tubelib.RUNNING))
	node.name = "tubelib_addons1:liquidsampler_active"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):start(CYCLE_TIME)
	return false
end	

local function switch_off(pos, node)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", tubelib.STATE_STOPPED)
	meta:set_string("infotext", "Liquid Sampler "..number..": stopped")
	meta:set_string("formspec", formspec(meta, tubelib.STOPPED))
	node.name = "tubelib_addons1:liquidsampler"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):stop()
	return false
end	

local function goto_fault(pos, node)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", tubelib.STATE_FAULT)
	meta:set_string("infotext", "Liquid Sampler "..number..": fault")
	meta:set_string("formspec", formspec(meta, tubelib.FAULT))
	node.name = "tubelib_addons1:liquidsampler"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):start(20)
	return false
end	

local function goto_standby(pos, node)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", tubelib.STATE_STANDBY)
	meta:set_string("infotext", "Liquid Sampler "..number..": standby")
	meta:set_string("formspec", formspec(meta, tubelib.STANDBY))
	node.name = "tubelib_addons1:liquidsampler"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):start(20)
	return false
end	

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return count
end

local function on_receive_fields(pos, formname, fields, sender)
	if minetest.is_protected(pos, sender:get_player_name()) then
		return
	end
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local running = meta:get_int("running")
	if fields.button ~= nil then
		if running == tubelib.STATE_RUNNING then
			switch_off(pos, node)
			meta:set_int("running", tubelib.STATE_STOPPED)
		else
			meta:set_int("running", tubelib.STATE_RUNNING)
			switch_on(pos, node)
		end
	end
end

local function keep_running(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local running = meta:get_int("running")
	local water_pos = minetest.string_to_pos(meta:get_string("water_pos"))
	local res = sample_liquid(water_pos, meta)
	
	if res == nil then
		local node = minetest.get_node(pos)
		return goto_standby(pos, node)
	elseif res == true then
		if running <= 0 then
			local node = minetest.get_node(pos)
			return switch_on(pos, node)
		end
	elseif res == false then
		if running > 0 then
			local node = minetest.get_node(pos)
			return goto_fault(pos, node)
		end
	end
	meta:set_int("running", running)
	return true
end

minetest.register_node("tubelib_addons1:liquidsampler", {
	description = "Liquid Sampler",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_addons1_liquidsampler.png',
		'tubelib_addons1_liquidsampler_passive.png',
		'tubelib_addons1_liquidsampler.png',
		'tubelib_addons1_liquidsampler.png',
	},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("src", 4)
		inv:set_size("dst", 28)
	end,
	
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("player_name", placer:get_player_name())
		local number = tubelib.add_node(pos, "tubelib_addons1:liquidsampler")
		meta:set_string("number", number)
		local node = minetest.get_node(pos)
		local water_pos = get_pos(pos, node.param2, "L")
		meta:set_string("water_pos", minetest.pos_to_string(water_pos))
		switch_off(pos, node)
	end,

	on_receive_fields = on_receive_fields,

	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,
	
	on_timer = keep_running,
	on_rotate = screwdriver.disallow,

	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_node("tubelib_addons1:liquidsampler_active", {
	description = "Liquid Sampler",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_addons1_liquidsampler.png',
		{
			image = "tubelib_addons1_liquidsampler_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 2,
			},
		},
		'tubelib_addons1_liquidsampler.png',
		'tubelib_addons1_liquidsampler.png',
	},

	on_receive_fields = on_receive_fields,
	
	on_timer = keep_running,
	on_rotate = screwdriver.disallow,
	
	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
	drop = "tubelib_addons1:liquidsampler",
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	output = "tubelib_addons1:liquidsampler",
	recipe = {
		{"group:wood", "default:steel_ingot", "group:wood"},
		{"default:mese_crystal", "bucket:bucket_empty", "tubelib:tube1"},
		{"group:wood", "default:steel_ingot", "group:wood"},
	},
})

--------------------------------------------------------------- tubelib
tubelib.register_node("tubelib_addons1:liquidsampler", {"tubelib_addons1:liquidsampler_active"}, {
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		return tubelib.get_item(meta, "dst")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		minetest.get_node_timer(pos):start(CYCLE_TIME)
		return tubelib.put_item(meta, "src", item)
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "dst", item)
	end,
	
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "on" then
			return switch_on(pos, node)
		elseif topic == "off" then
			return switch_off(pos, node)
		elseif topic == "state" then
			local meta = minetest.get_meta(pos)
			local running = meta:get_int("running") or tubelib.STATE_STOPPED
			return tubelib.statestring(running)
		else
			return "not supported"
		end
	end,
})	
--------------------------------------------------------------- tubelib
