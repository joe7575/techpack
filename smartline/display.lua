--[[

	SmartLine
	=========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	display.lua:

]]--

  
  
lcdlib.register_display_entity("smartline:entity")

local function display_update(pos, objref) 
	local meta = minetest.get_meta(pos)
	local text = meta:get_string("text") or ""
	text = string.gsub(text, "|", " \n")
	local texture = lcdlib.make_multiline_texture(
		"default", text,
		120, 120, 9, "top", "#000")
	objref:set_properties({ textures = {texture},
							visual_size = {x=0.94, y=0.94} })
end

local function on_timer(pos)
	if tubelib.data_not_corrupted(pos) then
		local meta = minetest.get_meta(pos)
		lcdlib.update_entities(pos)
		return false
	end
	return false
end

local lcd_box = {
	type = "wallmounted",
	wall_top = {-8/16, 15/32, -8/16, 8/16, 8/16, 8/16}
}

minetest.register_node("smartline:display", {
	description = "SmartLine Display",
	inventory_image = 'smartline_display_inventory.png',
	tiles = {"smartline_display.png"},
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "wallmounted",
	node_box = lcd_box,
	selection_box = lcd_box,
	light_source = 6,
	
	display_entities = {
		["smartline:entity"] = { depth = 0.42,
			on_display_update = display_update},
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "smartline:display")
		local meta = minetest.get_meta(pos)
		meta:set_string("number", number)
		meta:set_string("text", " \n \nMinetest\nSmartLine Tools\n \nDisplay\nNumber: "..number)
		meta:set_int("startscreen", 1)
		lcdlib.update_entities(pos)
	end,

	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,

	on_timer = on_timer,
	on_place = lcdlib.on_place,
	on_construct = lcdlib.on_construct,
	on_destruct = lcdlib.on_destruct,
	on_rotate = lcdlib.on_rotate,
	groups = {cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_glass_defaults(),
})


minetest.register_craft({
	output = "smartline:display",
	recipe = {
		{"", "", ""},
		{"default:glass", "dye:green", "tubelib:wlanchip"},
		{"", "default:copper_ingot", ""},
	},
})

local function add_line(meta, payload)
	local text = meta:get_string("text")
	local rows
	if meta:get_int("startscreen") == 1 then
		rows = {}
		meta:set_int("startscreen", 0)
	else
		rows = string.split(text, "|")
	end
	if #rows > 8 then
		table.remove(rows, 1)
	end
	table.insert(rows, payload)
	text = table.concat(rows, "|")
	meta:set_string("text", text)
end

local function write_row(meta, payload)
	local text = meta:get_string("text")
	if type(payload) == "table" then
		local row = tonumber(payload.row) or 0
		if row > 9 then row = 9 end
		local str = payload.str or "oops"
		if row == 0 then
			meta:set_string("infotext", str)
			return 
		end
		local rows
		if meta:get_int("startscreen") == 1 then
			rows = {}
			meta:set_int("startscreen", 0)
		else
			rows = string.split(text, "|")
		end
		if #rows < 9 then
			for i = #rows, 9 do
				table.insert(rows, " ")
			end
		end
		rows[row] = str
		text = table.concat(rows, "|")
		meta:set_string("text", text)
	end
end

tubelib.register_node("smartline:display", {}, {
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		local timer = minetest.get_node_timer(pos)
		if topic == "text" then  -- add one line and scroll if necessary
			local meta = minetest.get_meta(pos)
			add_line(meta, payload)
			if not timer:is_started() then
				timer:start(1)
			end
		elseif topic == "row" then  -- overwrite the given row
			local meta = minetest.get_meta(pos)
			write_row(meta, payload)
			if not timer:is_started() then
				timer:start(1)
			end
		elseif topic == "clear" then  -- clear the screen
			local meta = minetest.get_meta(pos)
			meta:set_string("text", "")
			if not timer:is_started() then
				timer:start(1)
			end
		end
	end,
})		

