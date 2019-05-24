--[[

	Gravel Sieve Mod
	================

	v1.09 by JoSt
	Derived from the work of celeron55, Perttu Ahola  (furnace)
	Pipeworks support added by FiftySix

	Copyright (C) 2017-2018 Joachim Stolberg
	Copyright (C) 2011-2016 celeron55, Perttu Ahola <celeron55@gmail.com>
	Copyright (C) 2011-2016 Various Minetest developers and contributors

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	2017-06-14  v0.01  First version
	2017-06-15  v0.02  Manually use of the sieve added
	2017-06-17  v0.03  * Settings bug fixed
					   * Drop bug fixed
					   * Compressed Gravel block added (Inspired by Modern Hippie)
					   * Recipes for Compressed Gravel added
	2017-06-17  v0.04  * Support for manual and automatic gravel sieve
					   * Rarity now configurable
					   * Output is 50% gravel and 50% sieved gravel
	2017-06-20  v0.05  * Hammer sound bugfix
	2017-06-24 	v1.00  * Released version w/o any changes
	2017-07-08  V1.01  * extended for moreores
	2017-07-09  V1.02  * Cobblestone bugfix (NathanSalapat)
	                   * ore_probability is now global accessable (bell07)
	2017-08-29  V1.03  * Fix syntax listring (Jat15)
	2017-09-08  V1.04  * Adaption to Tubelib
	2017-11-03  V1.05  * Adaption to Tubelib v0.06
	2018-01-01  V1.06  * Hopper support added
	2018-01-02  V1.07  * changed to registered ores
	2018-02-09  V1.08  * Pipeworks support added, bugfix for issue #7
	2018-12-28  V1.09  * Ore probability calculation changed (thanks to obl3pplifp)
	                     tubelib aging added
]]--

gravelsieve = {
}

dofile(minetest.get_modpath("gravelsieve") .. "/hammer.lua")

local settings_get
if minetest.setting_get then
	settings_get = minetest.setting_get
else
	settings_get = function(...) endminetest.settings:get(...) end
end
gravelsieve.ore_rarity = tonumber(settings_get("gravelsieve_ore_rarity")) or 1.16
gravelsieve.ore_max_elevation = tonumber(settings_get("gravelsieve_ore_max_elevation")) or 0
gravelsieve.ore_min_elevation = tonumber(settings_get("gravelsieve_ore_min_elevation")) or -30912
local y_spread = math.max(1 + gravelsieve.ore_max_elevation - gravelsieve.ore_min_elevation, 1)

-- Increase the probability over the natural occurrence
local PROBABILITY_FACTOR = 3

-- tubelib aging feature
local AGING_LEVEL1 = nil
local AGING_LEVEL2 = nil
if minetest.get_modpath("tubelib") and tubelib ~= nil then
	AGING_LEVEL1 = 15 * tubelib.machine_aging_value
	AGING_LEVEL2 = 60 * tubelib.machine_aging_value
end

-- Ore probability table  (1/n)
gravelsieve.ore_probability = {
}


-- Pipeworks support
local pipeworks_after_dig = nil
local pipeworks_after_place = function(pos, placer) end

if minetest.get_modpath("pipeworks") and pipeworks ~= nil then
	pipeworks_after_dig = pipeworks.after_dig
	pipeworks_after_place = pipeworks.after_place
end

local function harmonic_sum(a, b)
	return 1 / ((1 / a) + (1 / b))
end

local function calculate_probability(item)
	local ymax = math.min(item.y_max, gravelsieve.ore_max_elevation)
	local ymin = math.max(item.y_min, gravelsieve.ore_min_elevation)
	return (gravelsieve.ore_rarity / PROBABILITY_FACTOR) *
			item.clust_scarcity / (item.clust_num_ores * ((ymax - ymin) / y_spread))
end

-- collect all registered ores and calculate the probability
local function add_ores()
	for _,item in  pairs(minetest.registered_ores) do
		if minetest.registered_nodes[item.ore] then
			local drop = minetest.registered_nodes[item.ore].drop
			if type(drop) == "string"
			and drop ~= item.ore
			and drop ~= ""
			and item.ore_type == "scatter"
			and item.wherein == "default:stone"
			and item.clust_scarcity ~= nil and item.clust_scarcity > 0
			and item.clust_num_ores ~= nil and item.clust_num_ores > 0
			and item.y_max ~= nil and item.y_min ~= nil then
				local probability = calculate_probability(item)
				if probability > 0 then
					local cur_probability = gravelsieve.ore_probability[drop]
					if cur_probability then
						gravelsieve.ore_probability[drop] = harmonic_sum(cur_probability, probability)
					else
						gravelsieve.ore_probability[drop] = probability
					end
				end
			end
		end
	end
	local overall_probability = 0.0
	for name,probability in pairs(gravelsieve.ore_probability) do
		minetest.log("info", ("[gravelsieve] %-32s %.02f"):format(name, probability))
		overall_probability = overall_probability + 1.0/probability
	end
	minetest.log("info", ("[gravelsieve] Overall probability %f"):format(overall_probability))
end

minetest.after(1, add_ores)

local sieve_formspec =
	"size[8,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;src;1,1.5;1,1;]"..
	"image[3,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
	"list[context;dst;4,0;4,4;]"..
	"list[current_player;main;0,4.2;8,4;]"..
	"listring[context;dst]"..
	"listring[current_player;main]"..
	"listring[context;src]"..
	"listring[current_player;main]"


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

local function aging(pos, meta)
	if AGING_LEVEL1 then
		local cnt = meta:get_int("tubelib_aging") + 1
		meta:set_int("tubelib_aging", cnt)
		if cnt > AGING_LEVEL1 and math.random(AGING_LEVEL2) == 1 then
			minetest.get_node_timer(pos):stop()
			minetest.swap_node(pos, {name = "gravelsieve:sieve_defect"})
		end
	end
end

-- handle the sieve animation
local function swap_node(pos, meta, start)
	local node = minetest.get_node(pos)
	local idx = meta:get_int("idx")
	if start then
		if idx == 3 then
			idx = 0
		end
	else
		idx = (idx + 1) % 4
	end
	meta:set_int("idx", idx)
	node.name = meta:get_string("node_name")..idx
	minetest.swap_node(pos, node)
	return idx == 3
end

-- place ores to dst according to the calculated probability
local function random_ore(inv, src)
	local num
	for ore, probability in pairs(gravelsieve.ore_probability) do
		if math.random(probability) == 1 then
			local item = ItemStack(ore)
			if inv:room_for_item("dst", item) then
				inv:add_item("dst", item)
				return true     -- ore placed
			end
		end
	end
	return false    -- gravel has to be moved
end


local function add_gravel_to_dst(meta, inv)
	-- maintain a counter for gravel kind selection
	local gravel_cnt = meta:get_int("gravel_cnt") + 1
	meta:set_int("gravel_cnt", gravel_cnt)

	if (gravel_cnt % 2) == 0 then  -- gravel or sieved gravel?
		inv:add_item("dst", ItemStack("default:gravel"))        -- add to dest
	else
		inv:add_item("dst", ItemStack("gravelsieve:sieved_gravel")) -- add to dest
	end
end


-- move gravel and ores to dst
local function move_src2dst(meta, pos, inv, src, dst)
	if inv:room_for_item("dst", dst) and inv:contains_item("src", src) then
		local res = swap_node(pos, meta, false)
		if res then                                     -- time to move one item?
			if src:get_name() == "default:gravel" then  -- will we find ore?
				if not random_ore(inv, src) then        -- no ore found?
					add_gravel_to_dst(meta, inv)
				end
			else
				inv:add_item("dst", ItemStack("gravelsieve:sieved_gravel")) -- add to dest
			end
			inv:remove_item("src", src)
		end
		return true  -- process finished
	end
	return false -- process still running
end

-- timer callback, alternatively called by on_punch
local function sieve_node_timer(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local gravel = ItemStack("default:gravel")
	local gravel_sieved = ItemStack("gravelsieve:sieved_gravel")

	if move_src2dst(meta, pos, inv, gravel) then
		aging(pos, meta)
		return true
	elseif move_src2dst(meta, pos, inv, gravel_sieved) then
		aging(pos, meta)
		return true
	else
		minetest.get_node_timer(pos):stop()
		return false
	end
end


for automatic = 0,1 do
for idx = 0,4 do
	local nodebox_data = {
		{ -8/16, -8/16, -8/16,   8/16, 4/16, -6/16 },
		{ -8/16, -8/16,  6/16,   8/16, 4/16,  8/16 },
		{ -8/16, -8/16, -8/16,  -6/16, 4/16,  8/16 },
		{  6/16, -8/16, -8/16,   8/16, 4/16,  8/16 },
		{ -6/16, -2/16, -6/16,  6/16, 8/16, 6/16 },
	}
	nodebox_data[5][5] =    (8 - 2*idx) / 16

	local node_name
	local description
	local tiles_data
	local tube_info
	if automatic == 0 then
		node_name = "gravelsieve:sieve"
		description = "Gravel Sieve"
		tiles_data = {
			-- up, down, right, left, back, front
			"gravelsieve_gravel.png",
			"gravelsieve_gravel.png",
			"gravelsieve_sieve.png",
			"gravelsieve_sieve.png",
			"gravelsieve_sieve.png",
			"gravelsieve_sieve.png",
		}
	else
		node_name = "gravelsieve:auto_sieve"
		description = "Automatic Gravel Sieve"
		tiles_data = {
			-- up, down, right, left, back, front
			"gravelsieve_gravel.png",
			"gravelsieve_gravel.png",
			"gravelsieve_auto_sieve.png",
			"gravelsieve_auto_sieve.png",
			"gravelsieve_auto_sieve.png",
			"gravelsieve_auto_sieve.png",
		}

		-- Pipeworks support
		tube_info = {
			insert_object = function(pos, node, stack, direction)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				if automatic == 0 then
					local meta = minetest.get_meta(pos)
					swap_node(pos, meta, true)
				else
					minetest.get_node_timer(pos):start(1.0)
				end
				return inv:add_item("src", stack)
			end,
			can_insert = function(pos, node, stack, direction)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				return inv:room_for_item("src", stack)
			end,
			input_inventory = "dst",
			connect_sides = {left = 1, right = 1, front = 1, back = 1, bottom = 1, top = 1}
		}
	end

	if idx == 3 then
		tiles_data[1] = "gravelsieve_top.png"
		not_in_creative_inventory = 0
	else
		not_in_creative_inventory = 1
	end


	minetest.register_node(node_name..idx, {
		description = description,
		tiles = tiles_data,
		drawtype = "nodebox",
        drop = node_name,

		tube = tube_info,     --  NEW

		node_box = {
			type = "fixed",
			fixed = nodebox_data,
		},
		selection_box = {
			type = "fixed",
			fixed = { -8/16, -8/16, -8/16,   8/16, 4/16, 8/16 },
		},

		on_timer = sieve_node_timer,

		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_int("idx", idx)        -- for the 4 sieve phases
			meta:set_int("gravel_cnt", 0)   -- counter to switch between gravel and sieved gravel
			meta:set_string("node_name", node_name)
			meta:set_string("formspec", sieve_formspec)
			local inv = meta:get_inventory()
			inv:set_size('src', 1)
			inv:set_size('dst', 16)
		end,

		-- Pipeworks support
		after_dig_node = pipeworks_after_dig,

		after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", "Gravel Sieve")

			-- Pipeworks support
			pipeworks_after_place(pos, placer)
		end,

		on_metadata_inventory_move = function(pos)
			if automatic == 0 then
				local meta = minetest.get_meta(pos)
				swap_node(pos, meta, true)
			else
				minetest.get_node_timer(pos):start(1.0)
			end
		end,

		on_metadata_inventory_take = function(pos)
			if automatic == 0 then
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				if inv:is_empty("src") then
					-- sieve should be empty
					meta:set_int("idx", 2)
					swap_node(pos, meta, false)
					meta:set_int("gravel_cnt", 0)
				end
			else
				minetest.get_node_timer(pos):start(1.0)
			end
		end,

		on_metadata_inventory_put = function(pos)
			if automatic == 0 then
				local meta = minetest.get_meta(pos)
				swap_node(pos, meta, true)
			else
				minetest.get_node_timer(pos):start(1.0)
			end
		end,

		on_punch = function(pos, node, puncher, pointed_thing)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if inv:is_empty("dst") and inv:is_empty("src") then
				minetest.node_punch(pos, node, puncher, pointed_thing)
			else
				sieve_node_timer(pos, 0)
			end
		end,

		on_dig = function(pos, node, puncher, pointed_thing)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if inv:is_empty("dst") and inv:is_empty("src") then
				minetest.node_dig(pos, node, puncher, pointed_thing)
			end
		end,

		allow_metadata_inventory_put = allow_metadata_inventory_put,
		allow_metadata_inventory_move = allow_metadata_inventory_move,
		allow_metadata_inventory_take = allow_metadata_inventory_take,

		paramtype = "light",
		sounds = default.node_sound_wood_defaults(),
		paramtype2 = "facedir",
		sunlight_propagates = true,
		is_ground_content = false,
		groups = {choppy=2, cracky=1, not_in_creative_inventory=not_in_creative_inventory, tubedevice = 1, tubedevice_receiver = 1},
		drop = node_name.."3",
	})
end
end


------------------------------------------------------------------------
-- Optional adaption to tubelib
------------------------------------------------------------------------
if minetest.global_exists("tubelib") then
	minetest.register_node("gravelsieve:sieve_defect", {
		tiles = {
			-- up, down, right, left, back, front
			"gravelsieve_top.png",
			"gravelsieve_gravel.png",
			"gravelsieve_auto_sieve.png^tubelib_defect.png",
		},
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{ -8/16, -8/16, -8/16,   8/16, 4/16, -6/16 },
				{ -8/16, -8/16,  6/16,   8/16, 4/16,  8/16 },
				{ -8/16, -8/16, -8/16,  -6/16, 4/16,  8/16 },
				{  6/16, -8/16, -8/16,   8/16, 4/16,  8/16 },
				{ -6/16, -2/16, -6/16,   6/16, 2/16,  6/16 },
			},
		},
		selection_box = {
			type = "fixed",
			fixed = { -8/16, -8/16, -8/16,   8/16, 4/16, 8/16 },
		},

		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_int("idx", 0)        -- for the 4 sieve phases
			meta:set_int("gravel_cnt", 0)   -- counter to switch between gravel and sieved gravel
			meta:set_string("node_name", "gravelsieve:auto_sieve")
			meta:set_string("formspec", sieve_formspec)
			local inv = meta:get_inventory()
			inv:set_size('src', 1)
			inv:set_size('dst', 16)
		end,

		after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", "Gravel Sieve")
		end,

		on_dig = function(pos, node, puncher, pointed_thing)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if inv:is_empty("dst") and inv:is_empty("src") then
				minetest.node_dig(pos, node, puncher, pointed_thing)
			end
		end,

		paramtype = "light",
		sounds = default.node_sound_wood_defaults(),
		paramtype2 = "facedir",
		sunlight_propagates = true,
		is_ground_content = false,
		groups = {choppy=2, cracky=1, not_in_creative_inventory=1},
	})

	tubelib.register_node("gravelsieve:auto_sieve3",
		{
			"gravelsieve:auto_sieve0",
			"gravelsieve:auto_sieve1",
			"gravelsieve:auto_sieve2",
			"gravelsieve:sieve_defect",
		},
		{
		on_pull_item = function(pos, side)
			local meta = minetest.get_meta(pos)
			return tubelib.get_item(meta, "dst")
		end,
		on_push_item = function(pos, side, item)
			minetest.get_node_timer(pos):start(1.0)
			local meta = minetest.get_meta(pos)
			return tubelib.put_item(meta, "src", item)
		end,
		on_unpull_item = function(pos, side, item)
			local meta = minetest.get_meta(pos)
			return tubelib.put_item(meta, "dst", item)
		end,
		on_node_load = function(pos)
			minetest.get_node_timer(pos):start(1.0)
		end,
		on_node_repair = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_int("tubelib_aging", 0)
			meta:set_int("idx", 2)
			meta:set_string("node_name", "gravelsieve:auto_sieve")
			local inv = meta:get_inventory()
			inv:set_size('src', 1)
			inv:set_size('dst', 16)
			swap_node(pos, meta, false)
			minetest.get_node_timer(pos):start(1.0)
			return true
		end,
	})
end

minetest.register_node("gravelsieve:sieved_gravel", {
	description = "Sieved Gravel",
	tiles = {"default_gravel.png"},
	groups = {crumbly=2, falling_node=1, not_in_creative_inventory=1},
	sounds = default.node_sound_gravel_defaults(),
})

minetest.register_node("gravelsieve:compressed_gravel", {
	description = "Compressed Gravel",
	tiles = {"gravelsieve_compressed_gravel.png"},
	groups = {cracky=2, crumbly = 2, cracky = 2},
	sounds = default.node_sound_gravel_defaults(),
})

minetest.register_craft({
	output = "gravelsieve:sieve",
	recipe = {
		{"group:wood", "",                      "group:wood"},
		{"group:wood", "default:steel_ingot",   "group:wood"},
		{"group:wood", "",                      "group:wood"},
	},
})

minetest.register_craft({
	output = "gravelsieve:auto_sieve",
	type = "shapeless",
	recipe = {
		"gravelsieve:sieve", "default:mese_crystal",  "default:mese_crystal",
	},
})

minetest.register_craft({
	output = "gravelsieve:compressed_gravel",
	recipe = {
		{"gravelsieve:sieved_gravel", "gravelsieve:sieved_gravel"},
		{"gravelsieve:sieved_gravel", "gravelsieve:sieved_gravel"},
	},
})

minetest.register_craft({
	type = "cooking",
	output = "default:cobble",
	recipe = "gravelsieve:compressed_gravel",
	cooktime = 10,
})

minetest.register_alias("gravelsieve:sieve", "gravelsieve:sieve3")
minetest.register_alias("gravelsieve:auto_sieve", "gravelsieve:auto_sieve3")

-- adaption to hopper
if minetest.get_modpath("hopper") and hopper ~= nil and hopper.add_container ~= nil then
	hopper:add_container({
		{"bottom", "gravelsieve:auto_sieve0", "src"},
		{"top", "gravelsieve:auto_sieve0", "dst"},
		{"side", "gravelsieve:auto_sieve0", "src"},

		{"bottom", "gravelsieve:auto_sieve1", "src"},
		{"top", "gravelsieve:auto_sieve1", "dst"},
		{"side", "gravelsieve:auto_sieve1", "src"},

		{"bottom", "gravelsieve:auto_sieve2", "src"},
		{"top", "gravelsieve:auto_sieve2", "dst"},
		{"side", "gravelsieve:auto_sieve2", "src"},

		{"bottom", "gravelsieve:auto_sieve3", "src"},
		{"top", "gravelsieve:auto_sieve3", "dst"},
		{"side", "gravelsieve:auto_sieve3", "src"},
	})
end

-- adaption to Circular Saw
if minetest.get_modpath("moreblocks") then

	stairsplus:register_all("gravelsieve", "compressed_gravel", "gravelsieve:compressed_gravel", {
		description="Compressed Gravel",
		groups={cracky=2, crumbly=2, choppy=2, not_in_creative_inventory=1},
		tiles = {"gravelsieve_compressed_gravel.png"},
		sounds = default.node_sound_stone_defaults(),
	})
end


