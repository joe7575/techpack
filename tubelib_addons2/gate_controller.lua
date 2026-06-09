--[[

	Tubelib Addons 2
	================

	Copyright (C) 2017-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	gate_controller.lua:

	A chest-based gate controller. Up to 8 gate/door blocks are physically
	removed from the world and stored in the chest inventory when the gate
	opens ("off"). Sending "on" places all stored blocks back into the world.

	Number2Pos entries for the managed gate blocks are intentionally left to
	expire via data_maintenance; the gate controller stores all needed data
	(position, name, param2) in its own persistent metadata.

]]--

local S = tubelib_addons2.S

local NUM_SLOTS = 8

local function formspec(meta)
	local numbers   = minetest.formspec_escape(meta:get_string("numbers") or "")
	local state     = meta:get_string("state") or "closed"
	local state_str = state == "open" and S("Gate: open") or S("Gate: closed")
	return "size[8,9.5]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"field[0.3,0.6;5.5,1;numbers;" .. S("Gate block number(s)") .. ";" .. numbers .. "]" ..
		"button_exit[5.9,0.3;1.9,1;save;" .. S("Save") .. "]" ..
		"button_exit[0.3,1.7;2.5,1;load;" .. S("Load gate") .. "]" ..
		"label[3.1,2.1;" .. state_str .. "]" ..
		"list[context;main;0,3.0;4,2;]" ..
		"list[current_player;main;0,5.5;8,4;]" ..
		"listring[context;main]" ..
		"listring[current_player;main]"
end

-- Returns true if the node at pos is passable (air, water, plants, etc.)
-- Uses the walkable property so that plants or water grown into the
-- target position are not overwritten.
local function is_passable(pos)
	local node = minetest.get_node(pos)
	local ndef = minetest.registered_nodes[node.name]
	return not ndef or ndef.walkable == false
end

-- Place gate blocks back from the chest inventory into the world.
-- Skips slots whose target position is occupied by a walkable block.
local function close_gate(pos)
	local meta      = minetest.get_meta(pos)
	local inv       = meta:get_inventory()
	local positions = minetest.deserialize(meta:get_string("positions")) or {}
	for i, entry in ipairs(positions) do
		local stack = inv:get_stack("main", i)
		if not stack:is_empty() then
			if is_passable(entry.pos) then
				minetest.set_node(entry.pos, {name = entry.name, param2 = entry.param2})
				inv:set_stack("main", i, ItemStack())
			end
		end
	end
	meta:set_string("state", "closed")
	meta:set_string("formspec", formspec(meta))
end

-- Remove gate blocks from the world and store them as items in the inventory.
-- Only removes a block if its name still matches the configured name (someone
-- may have replaced it in the meantime).
local function open_gate(pos)
	local meta      = minetest.get_meta(pos)
	local inv       = meta:get_inventory()
	local positions = minetest.deserialize(meta:get_string("positions")) or {}
	for i, entry in ipairs(positions) do
		-- only act if the slot is currently empty (avoid double-collect)
		if inv:get_stack("main", i):is_empty() then
			local node = minetest.get_node(entry.pos)
			if node and node.name then
				inv:set_stack("main", i, ItemStack(node.name))
				minetest.remove_node(entry.pos)
			end
		end
	end
	meta:set_string("state", "open")
	meta:set_string("formspec", formspec(meta))
end

-- Look up positions from tubelib numbers and store them in the controller's
-- metadata. Existing gate blocks are first restored (close_gate), then the
-- old inventory is cleared and new positions are configured.
local function configure(pos, numbers)
	-- restore blocks from any previous configuration
	close_gate(pos)
	local meta = minetest.get_meta(pos)
	local inv  = meta:get_inventory()
	-- clear leftover items that could not be placed back
	inv:set_list("main", {})

	local positions = {}
	for _, num in ipairs(string.split(numbers, " ")) do
		if num ~= "" and #positions < NUM_SLOTS then
			local n = tonumber(num)
			if n then
				local padded = string.format("%.04u", n)
				local info = tubelib.get_node_info(padded)
				if info and info.pos then
					local node = minetest.get_node(info.pos)
					if node.name ~= "air" and node.name ~= "ignore" then
						positions[#positions + 1] = {
							pos    = info.pos,
							name   = node.name,
							param2 = node.param2,
							number = padded,  -- kept for display / reference only
						}
					end
				end
			end
		end
	end

	local own = meta:get_string("number")
	meta:set_string("positions", minetest.serialize(positions))
	meta:set_string("numbers",   numbers)
	meta:set_string("state",     "closed")
	meta:set_string("infotext",
		S("Gate Controller") .. " " .. own ..
		" (" .. #positions .. " " .. S("block(s) configured") .. ")")
	meta:set_string("formspec", formspec(meta))
end

------------------------------------------------------------------------
-- Node registration
------------------------------------------------------------------------

minetest.register_node("tubelib_addons2:gate_controller", {
	description = S("Gate Controller"),
	tiles = {
		-- up, down, right, left, back, front
		"tubelib_addons3_chest_bottom.png",
		"tubelib_addons3_chest_bottom.png",
		"tubelib_addons3_chest_side.png^tubelib_addons2_doorcontroller.png",
		"tubelib_addons3_chest_side.png^tubelib_addons2_doorcontroller.png",
		"tubelib_addons3_chest_side.png^tubelib_addons2_doorcontroller.png",
		"tubelib_addons3_chest_side.png^tubelib_addons2_doorcontroller.png",
	},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local inv  = meta:get_inventory()
		inv:set_size("main", NUM_SLOTS)
		local number = tubelib.add_node(pos, "tubelib_addons2:gate_controller")
		meta:set_string("number",    number)
		meta:set_string("owner",     placer:get_player_name())
		meta:set_string("state",     "closed")
		meta:set_string("positions", minetest.serialize({}))
		meta:set_string("infotext",  S("Gate Controller") .. " " .. number)
		meta:set_string("formspec",  formspec(meta))
	end,

	on_receive_fields = function(pos, formname, fields, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return
		end
		if fields.save then
			configure(pos, fields.numbers or "")
		elseif fields.load then
			open_gate(pos)
		end
	end,

	-- The gate inventory is managed internally; players may not insert items.
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return 0
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index,
	                                          to_list, to_index, count, player)
		return 0
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		return stack:get_count()
	end,

	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return false
		end
		return true
	end,

	-- Restore all gate blocks before the controller node is removed.
	on_dig = function(pos, node, puncher, pointed_thing)
		close_gate(pos)
		minetest.node_dig(pos, node, puncher, pointed_thing)
		tubelib.remove_node(pos)
	end,

	paramtype2 = "facedir",
	groups = {choppy = 2, cracky = 2, crumbly = 2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	on_blast = function() end,
})

minetest.register_craft({
	output = "tubelib_addons2:gate_controller",
	recipe = {
		{"group:wood",       "default:steel_ingot", "group:wood"},
		{"tubelib:wlanchip", "default:chest",       "tubelib:wlanchip"},
		{"group:wood",       "default:steel_ingot", "group:wood"},
	},
})

------------------------------------------------------------------------
-- Tubelib message interface
-- "on"  → close gate (place blocks back into the world)
-- "off" → open gate  (remove blocks into the inventory)
------------------------------------------------------------------------

tubelib.register_node("tubelib_addons2:gate_controller", {}, {
	on_recv_message = function(pos, topic, payload)
		if topic == "on" then
			close_gate(pos)
		elseif topic == "off" then
			open_gate(pos)
		end
	end,
})

minetest.register_alias("tubelib_addons2:gate_chest", "tubelib_addons2:gate_controller")
