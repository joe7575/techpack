--[[

	sl_robot
	========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	base.lua:

]]--

local FUEL_AMOUNT = 1000000

local sHELP = [[SaferLua Robot

 The SaferLua Robot can be programmed in Lua by
 means of this Robot Base.
 The Robot needs Bio Fluel to operate.
 
]]

local Cache = {}

local tCommands = {}
local tFunctions = {" Overview", " Data structures"}
local tHelpTexts = {[" Overview"] = sHELP, [" Data structures"] = safer_lua.DataStructHelp}
local sFunctionList = ""
local tFunctionIndex = {}

minetest.after(2, function() 
	sFunctionList = table.concat(tFunctions, ",") 
	for idx,key in ipairs(tFunctions) do
		tFunctionIndex[key] = idx
	end
end)

local function output(pos, text)
	local meta = minetest.get_meta(pos)
	text = meta:get_string("output") .. "\n" .. (text or "")
	text = text:sub(-500,-1)
	meta:set_string("output", text)
end

--
-- API functions for function/action registrations
--
function sl_robot.register_action(key, attr)
	tCommands[key] = attr.cmnd
	table.insert(tFunctions, " $"..key)
	tHelpTexts[" $"..key] = attr.help
end

local function merge(dest, keys, values)
  for idx,key in ipairs(keys) do
    dest.env[key] = values[idx]
  end
  return dest
end

sl_robot.register_action("print", {
	cmnd = function(self, text1, text2, text3)
		local pos = self.meta.pos
		text1 = tostring(text1 or "")
		text2 = tostring(text2 or "")
		text3 = tostring(text3 or "")
		output(pos, text1..text2..text3)
	end,
	help = " $print(text,...)\n"..
		" Send a text line to the output window.\n"..
		" The function accepts up to 3 text strings\n"..
		' e.g. $print("Hello ", name, " !")'
})


local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = minetest.get_meta(pos)
	if meta:get_int("state") == tubelib.RUNNING then
		return 0
	end
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
	local meta = minetest.get_meta(pos)
	if meta:get_int("state") == tubelib.RUNNING then
		return 0
	end
	return stack:get_count()
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = minetest.get_meta(pos)
	if meta:get_int("state") == tubelib.RUNNING then
		return 0
	end
	return count
end	

local function formspec1(meta)
	local running = meta:get_int("state") == tubelib.RUNNING
	local cmnd = running and "stop;Stop" or "start;Start" 
	local init = meta:get_string("init")
	local fuel = math.floor((meta:get_int("fuel") * 100.0) / FUEL_AMOUNT) 
	init = minetest.formspec_escape(init)
	return "size[10,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;Inv,init,loop,outp,notes,help;1;;true]"..
	"label[5.3,0.5;1]label[6.3,0.5;2]label[7.3,0.5;3]label[8.3,0.5;4]"..
	"list[context;main;5,1;4,2;]"..
	"label[5.3,3;5]label[6.3,3;6]label[7.3,3;7]label[8.3,3;8]"..
	"list[context;fuel;1,1.7;1,1;]"..
	"item_image[1,1.7;1,1;tubelib_addons1:biofuel]"..
	"image[2,1.7;1,1;default_furnace_fire_bg.png^[lowpart:"..
	(fuel)..":default_furnace_fire_fg.png]"..
	"list[current_player;main;1,4;8,4;]"..
	"listring[context;main]"..
	"listring[current_player;main]"

end

local function formspec2(meta)
	local running = meta:get_int("state") == tubelib.RUNNING
	local cmnd = running and "stop;Stop" or "start;Start" 
	local init = meta:get_string("init")
	init = minetest.formspec_escape(init)
	return "size[10,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;Inv,init,loop,outp,notes,help;2;;true]"..
	"textarea[0.3,0.2;10,8.3;init;function init();"..init.."]"..
	"label[0,7.3;end]"..
	"button_exit[4.4,7.5;1.8,1;cancel;Cancel]"..
	"button[6.3,7.5;1.8,1;save;Save]"..
	"button[8.2,7.5;1.8,1;"..cmnd.."]"
end

local function formspec3(meta)
	local running = meta:get_int("state") == tubelib.RUNNING
	local cmnd = running and "stop;Stop" or "start;Start"
	local loop = meta:get_string("loop")
	loop = minetest.formspec_escape(loop)
	return "size[10,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;Inv,init,loop,outp,notes,help;3;;true]"..
	"textarea[0.3,0.2;10,8.3;loop;function loop(ticks, elapsed);"..loop.."]"..
	"label[0,7.3;end]"..
	"button_exit[4.4,7.5;1.8,1;cancel;Cancel]"..
	"button[6.3,7.5;1.8,1;save;Save]"..
	"button[8.2,7.5;1.8,1;"..cmnd.."]"
end

local function formspec4(meta)
	local running = meta:get_int("state") == tubelib.RUNNING
	local cmnd = running and "stop;Stop" or "start;Start" 
	local output = meta:get_string("output")
	output = minetest.formspec_escape(output)
	return "size[10,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;Inv,init,loop,outp,notes,help;4;;true]"..
	"textarea[0.3,0.2;10,8.3;help;Output:;"..output.."]"..
	"button[4.4,7.5;1.8,1;clear;Clear]"..
	"button[6.3,7.5;1.8,1;update;Update]"..
	"button[8.2,7.5;1.8,1;"..cmnd.."]"
end

local function formspec5(meta)
	local notes = meta:get_string("notes")
	notes = minetest.formspec_escape(notes)
	return "size[10,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;Inv,init,loop,outp,notes,help;5;;true]"..
	"textarea[0.3,0.2;10,8.3;notes;Notepad:;"..notes.."]"..
	"button_exit[6.3,7.5;1.8,1;cancel;Cancel]"..
	"button[8.2,7.5;1.8,1;save;Save]"
end

local function formspec6(items, pos, text)
	text = minetest.formspec_escape(text)
	return "size[10,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;Inv,init,loop,outp,notes,help;6;;true]"..
	"label[0,-0.2;Functions:]"..
	"dropdown[0.3,0.2;10,8.3;functions;"..items..";"..pos.."]"..
	"textarea[0.3,1.3;10,8;help;Help:;"..text.."]"
end

local function error(pos, err)
	output(pos, err)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_string("formspec", formspec4(meta))
	meta:set_string("infotext", "Robot Base "..number..": error")
	meta:set_int("state", tubelib.STOPPED)
	minetest.get_node_timer(pos):stop()
	local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
	minetest.sound_play('sl_robot_error', {pos = robot_pos})
	return false
end

-- check the fuel level and return false if empty
local function check_fuel(pos, meta)
	local fuel = meta:get_int("fuel")
	if fuel <= 0 then
		if tubelib.get_this_item(meta, "fuel", 1) == nil then
			return false
		end
		fuel = FUEL_AMOUNT
	end
	meta:set_int("fuel", fuel)
	return true
end

local function reset_robot(pos, meta)
	local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
	minetest.log("action", "[robby] reset_robot "..meta:get_string("robot_pos"))

	if robot_pos then
		minetest.after(5, minetest.remove_node, table.copy(robot_pos))
	end
	
	local param2 = (minetest.get_node(pos).param2 + 1) % 4
	robot_pos = sl_robot.new_pos(pos, param2, 1)
	local pos_below = {x=robot_pos.x, y=robot_pos.y-1, z=robot_pos.z}
	
	meta:set_string("robot_pos", minetest.pos_to_string(robot_pos))
	meta:set_int("robot_param2", param2)
	sl_robot.place_robot(robot_pos, pos_below, param2, nil)	
end


local function compile(pos, meta, number)
	local init = meta:get_string("init")
	local loop = meta:get_string("loop")
	local owner = meta:get_string("owner")
	local env = table.copy(tCommands)
	reset_robot(pos, meta)
	env.meta = {pos=pos, owner=owner, number=number, error=error}
	local co, code = safer_lua.co_create(pos, init, loop, env, error)
	
	if co then
		Cache[number] = {code=code, co=co}
		return true
	end
	return false
end

local function start_robot(pos)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	
	meta:set_string("output", "<press update>")
	
	if not check_fuel(pos, meta) then 
		local number = meta:get_string("number")
		meta:set_string("infotext", "Robot Base "..number..": no fuel")
		return false 
	end
	if compile(pos, meta, number) then
		meta:set_int("state", tubelib.RUNNING)
		meta:set_string("formspec", formspec4(meta))
		minetest.get_node_timer(pos):start(1)
		meta:set_string("infotext", "Robot Base "..number..": running")
		return true
	end
	return false
end

local function stop_robot(pos)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
	meta:set_int("state", tubelib.STOPPED)
	minetest.get_node_timer(pos):stop()
	meta:set_string("infotext", "Robot Base "..number..": stopped")
	meta:set_string("formspec", formspec3(meta))
	if Cache[number] then
		local code =  Cache[number].code
		local env = getfenv(code)
		sl_robot.remove_robot(robot_pos)
	end
end

local function call_loop(pos, meta, elapsed)
	local t = minetest.get_us_time()
	local number = meta:get_string("number")
	if Cache[number] or compile(pos, meta, number) then
		local cpu = meta:get_int("cpu") or 0
		local code = Cache[number].code
		local co = Cache[number].co
		local res = safer_lua.co_resume(pos, co, code, error)
		if res then 
			t = minetest.get_us_time() - t
			cpu = math.floor(((cpu * 20) + t) / 21)
			meta:set_int("cpu", cpu)
			local robot_pos = meta:get_string("robot_pos")
			meta:set_string("infotext", "Robot Base "..number..": running ("..cpu.."us) "..robot_pos)
			meta:set_int("fuel", meta:get_int("fuel") - t)
		end
		return res
	end
	return false
end

local function on_timer(pos, elapsed)
	local meta = minetest.get_meta(pos)
	
	--so some maintenance every 10 cycles
	local ticks = (meta:get_int("ticks") or 0) + 1
	meta:set_int("ticks", ticks)
	if (ticks % 100) == 0 then
		if not check_fuel(pos, meta) then 
			local number = meta:get_string("number")
			meta:set_string("infotext", "Robot Base "..number..": no fuel")
			return false 
		end
	end
	return call_loop(pos, meta, elapsed)
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local meta = minetest.get_meta(pos)
	
	--print(dump(fields))
	if fields.cancel == nil then
		if fields.init then
			meta:set_string("init", fields.init)
			meta:set_string("formspec", formspec2(meta))
		elseif fields.loop then
			meta:set_string("loop", fields.loop)
			meta:set_string("formspec", formspec3(meta))
		elseif fields.notes then
			meta:set_string("notes", fields.notes)
			meta:set_string("formspec", formspec5(meta))
		end	
	end
	
	if fields.update then
		meta:set_string("formspec", formspec4(meta))
	elseif fields.clear then
		meta:set_string("output", "<press update>")
		meta:set_string("formspec", formspec4(meta))
	elseif fields.tab == "1" then
		meta:set_string("formspec", formspec1(meta))
	elseif fields.tab == "2" then
		meta:set_string("formspec", formspec2(meta))
	elseif fields.tab == "3" then
		meta:set_string("formspec", formspec3(meta))
	elseif fields.tab == "4" then
		meta:set_string("formspec", formspec4(meta))
	elseif fields.tab == "5" then
		meta:set_string("formspec", formspec5(meta))
	elseif fields.tab == "6" then
		meta:set_string("formspec", formspec6(sFunctionList, 1, sHELP))
	elseif fields.start == "Start" then
		start_robot(pos)
		minetest.log("action", player:get_player_name() ..
			" starts the sl_robot at ".. minetest.pos_to_string(pos))
	elseif fields.stop == "Stop" then
		stop_robot(pos)
	elseif fields.functions then
		local key = fields.functions
		local text = tHelpTexts[key] or ""
		local pos = tFunctionIndex[key] or 1
		meta:set_string("formspec", formspec6(sFunctionList, pos, text))
	end
end

minetest.register_node("sl_robot:base", {
	description = "SaferLua Robot Base",
	stack_max = 1,
	tiles = {
		-- up, down, right, left, back, front
		'sl_robot_base_top.png',
		'sl_robot_base_top.png',
		'sl_robot_base_right.png',
		'sl_robot_base_left.png',
		'sl_robot_base_front.png',
		'sl_robot_base_front.png',
	},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size('main', 8)
		inv:set_size('fuel', 1)
	end,
	
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local number = tubelib.add_node(pos, "sl_robot:base")
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("number", number)
		meta:set_int("state", tubelib.STOPPED)
		meta:set_string("init", "-- called only once")
		meta:set_string("loop", "-- called cyclically")
		meta:set_string("notes", "For your notes / snippets")
		meta:set_string("formspec", formspec1(meta))
		meta:set_string("infotext", "Robot Base "..number..": stopped")
	end,

	on_receive_fields = on_receive_fields,
	
	on_dig = function(pos, node, puncher, pointed_thing)
		if minetest.is_protected(pos, puncher:get_player_name()) then
			return
		end
		local meta = minetest.get_meta(pos)
		if meta:get_int("state") == tubelib.RUNNING then
			return
		end
		minetest.node_dig(pos, node, puncher, pointed_thing)
		tubelib.remove_node(pos)
	end,
	
	on_timer = on_timer,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {cracky = 1},
	sounds = default.node_sound_metal_defaults(),
})


--minetest.register_craft({
--	type = "shapeless",
--	output = "sl_robot:robot",
--	recipe = {"smartline:controller"}
--})

