--[[

	SmartLine
	=========
	
	Part of the SmartLine mod
	
	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	formspec.lua:

	controller formspecs
]]--

smartline.NUM_RULES = 8

local SIZE = "size[13,8]"

local sHELP = [[SmartLine Controller Help

Control other nodes by means of rules like:
    IF <condition> THEN <action>

These rules allow to execute actions based on conditions.
Examples for conditions are:
 - the Player Detector detects a player
 - a button is pressed
 - a node state is fault, blocked, standby,...
  
Actions are:
 - switch on/off tubelib nodes, like lamps, machines
 - send chat messages to the owner
 - output a text message to the display
 
The controller executes all rules cyclically.
The cycle time for each rule is configurable
(1..1000 sec). 
0 means, the rule will only be called, when
the controller received a command from
another node, like buttons.

Actions can be deleyed. Therefore, the
after value can be set (0..1000 sec).

Edit command examples:
 - 'x 1 8'  exchange rows 1 with row 8
 - 'c 1 2'  copy row 1 to 2
 - 'd 3'    delete row 3

The 'outp' tab is for debugging outputs via 'print'
The 'notes' tab for your notes.

The controller needs battery power to work.
The battery pack has to be placed near the 
controller (1 node distance). 
The needed battery power is directly dependent 
on the CPU time the controller consumes.

For more information, see: goo.gl/fF5ap6
]]

-- to simplify the search for a pressed main form button (condition/action)
local lButtonKeys = {}

for idx = 1,smartline.NUM_RULES do
	lButtonKeys[#lButtonKeys+1] = "cond"..idx
	lButtonKeys[#lButtonKeys+1] = "actn"..idx
end	

local function buttons(s)
	return "button_exit[7.4,7.5;1.8,1;cancel;Cancel]"..
	"button[9.3,7.5;1.8,1;save;Save]"..
	"button[11.2,7.5;1.8,1;"..s.."]"
end

function smartline.formspecError(meta)
	local running = meta:get_int("state") == tubelib.RUNNING
	local cmnd = running and "stop;Stop" or "start;Start" 
	local init = meta:get_string("init")
	init = minetest.formspec_escape(init)
	return "size[4,3]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"label[0,0;No Battery?]"..
	"button[1,2;1.8,1;start;Start]"
end

local function button(data)
	if data then
		return data.button
	else
		return "..."
	end
end

local function formspec_rules(fs_data)
	local tbl = {"field[0,0;0,0;_type_;;main]"..
		"label[0.8,0;Cycle/s:]label[2.8,0;IF  cond:]label[7,0;THEN  action:]label[11.4,0;after/s:]"}
		
	for idx = 1,smartline.NUM_RULES do
		local ypos = idx * 0.75 - 0.4
		tbl[#tbl+1] = "label[0,"..(0.2+ypos)..";"..idx.."]"
		tbl[#tbl+1] = "field[0.9,"..(0.3+ypos)..";1.8,1;cycle"..idx..";;"..(fs_data[idx].cycle or "").."]"
		tbl[#tbl+1] = "button[2.5,"..ypos..";4.3,1;cond"..idx..";"..button(fs_data[idx].cond).."]"
		tbl[#tbl+1] = "button[6.8,"..ypos..";4.3,1;actn"..idx..";"..button(fs_data[idx].actn).."]"
		tbl[#tbl+1] = "field[11.4,"..(0.3+ypos)..";1.8,1;after"..idx..";;"..(fs_data[idx].after or "").."]"
	end
	return table.concat(tbl)
end

function smartline.store_main_form_data(meta, fields)
	local fs_data = minetest.deserialize(meta:get_string("fs_data"))
	for idx = 1,smartline.NUM_RULES do
		fs_data[idx].cycle = fields["cycle"..idx] or ""
		fs_data[idx].after = fields["after"..idx] or "0"
	end	
	meta:set_string("fs_data", minetest.serialize(fs_data))
end

function smartline.main_form_button_pressed(fields)
	for _,key in ipairs(lButtonKeys) do
		if fields[key] then
			return key
		end
	end
	return nil
end

function smartline.formspecSubMenu(meta, key)
	local fs_data = minetest.deserialize(meta:get_string("fs_data"))
	if key:sub(1,4) == "cond" then
		local row = tonumber(key:sub(5,5))
		return smartline.cond_formspec(row, fs_data[row].cond)
	else
		local row = tonumber(key:sub(5,5))
		return smartline.actn_formspec(row, fs_data[row].actn)
	end	
end

function smartline.formspec_button_update(meta, fields)	
	local fs_data = minetest.deserialize(meta:get_string("fs_data"))
	local row = tonumber(fields._row_ or 1)
	print("row", row)
	if fields._col_ == "cond" then
		fs_data[row].cond = smartline.cond_eval_input(fs_data[row].cond, fields)
	elseif fields._col_ == "actn" then
		fs_data[row].actn = smartline.actn_eval_input(fs_data[row].actn, fields)
	end
	meta:set_string("fs_data", minetest.serialize(fs_data))
end

function smartline.cond_formspec_update(meta, fields)	
	local fs_data = minetest.deserialize(meta:get_string("fs_data"))
	local row = tonumber(fields._row_ or 1)
	fs_data[row].cond = smartline.cond_eval_input(fs_data[row].cond, fields)
	meta:set_string("formspec", smartline.cond_formspec(row, fs_data[row].cond))
	meta:set_string("fs_data", minetest.serialize(fs_data))
end

function smartline.actn_formspec_update(meta, fields)	
	local fs_data = minetest.deserialize(meta:get_string("fs_data"))
	local row = tonumber(fields._row_ or 1)
	fs_data[row].actn = smartline.actn_eval_input(fs_data[row].actn, fields)
	meta:set_string("formspec", smartline.actn_formspec(row, fs_data[row].actn))
	meta:set_string("fs_data", minetest.serialize(fs_data))
end


function smartline.formspecRules(meta, fs_data, output)
	local running = meta:get_int("state") == tubelib.RUNNING
	local cmnd = running and "stop;Stop" or "start;Start" 
	local init = meta:get_string("init")
	init = minetest.formspec_escape(init)
	return SIZE..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;rules,outp,notes,help;1;;true]"..
	formspec_rules(fs_data)..
	"label[0.2,7.0;"..output.."]"..
	"field[0.3,7.8;4,1;cmnd;;<cmnd>]"..
	"button[4.0,7.5;1.5,1;go;GO]"..
	buttons(cmnd)
end

function smartline.formspecOutput(meta)
	local running = meta:get_int("state") == tubelib.RUNNING
	local cmnd = running and "stop;Stop" or "start;Start" 
	local output = meta:get_string("output")
	output = minetest.formspec_escape(output)
	return SIZE..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;rules,outp,notes,help;2;;true]"..
	"textarea[0.3,0.2;13,8.3;output;Output:;"..output.."]"..
	"button[7.4,7.5;1.8,1;clear;Clear]"..
	"button[9.3,7.5;1.8,1;update;Update]"..
	"button[11.2,7.5;1.8,1;"..cmnd.."]"
end

function smartline.formspecNotes(meta)
	local running = meta:get_int("state") == tubelib.RUNNING
	local cmnd = running and "stop;Stop" or "start;Start" 
	local notes = meta:get_string("notes")
	if notes == "" then notes = "<space for your notes>" end
	notes = minetest.formspec_escape(notes)
	return SIZE..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;rules,outp,notes,help;3;;true]"..
	"textarea[0.3,0.2;13,8.3;notes;Notepad:;"..notes.."]"..
	buttons(cmnd)
end

function smartline.formspecHelp(offs)
	return SIZE..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;rules,outp,notes,help;4;;true]"..
	"field[0,0;0,0;_type_;;help]"..
	"label[0,"..(-offs/50)..";"..sHELP.."]"..
	--"label[0.2,0;test]"..
	"scrollbar[12,1;0.5,7;vertical;sb_help;"..offs.."]"
end



--local function my_on_receive_fields(pos, formname, fields, player)
--	local meta = minetest.get_meta(pos)
--	local owner = meta:get_string("owner")
--	local state = meta:get_int("state")
--	if not player or not player:is_player() then
--		return
--	end
--	local fs_data = minetest.deserialize(meta:get_string("fs_data")) or {}
--	local output = ""
--	local readonly = player:get_player_name() ~= owner
	
--	print("fields", dump(fields))
	
--	-- FIRST: test if command entered?
--	if fields.ok then
--		if not readonly then	
--			output = edit_command(fs_data, fields.cmnd)
--			smartline.stop_controller(pos, fs_data)
--			meta:set_string("formspec", formspec_main(tubelib.STOPPED, fs_data, output))
--			meta:set_string("fs_data", minetest.serialize(fs_data))
--		end
--	-- SECOND: eval none edit events (events based in __type__)?
--	elseif fields.help then
--		meta:set_string("formspec", formspec_help(1))
----	elseif fields.state then
----		meta:set_string("formspec", formspec_state(meta, fs_data))
----	elseif fields.update then
----		meta:set_string("formspec", formspec_state(meta, fs_data))
--	elseif fields._cancel_ then
--		fs_data = minetest.deserialize(meta:get_string("fs_old"))
--		meta:set_string("formspec", formspec_main(state, fs_data, sOUTPUT))
--	elseif fields.close then
--		meta:set_string("formspec", formspec_main(state, fs_data, sOUTPUT))
----	elseif fields.sb_help then
----		local evt = minetest.explode_scrollbar_event(fields.sb_help)
----		if evt.type == "CHG" then
----			meta:set_string("formspec", formspec_help(evt.value))
----		end
----	elseif fields.button then
----		if not readonly then
----			local number = meta:get_string("number")
----			local state = meta:get_int("state")
----			if state == tubelib.RUNNING then
----				smartline.stop_controller(pos, fs_data)
----				meta:set_string("formspec", formspec_main(tubelib.STOPPED, fs_data, sOUTPUT))
----			else
----				formspec2runtime_rule(number, owner, fs_data)
----				start_controller(pos, number, fs_data)
----				meta:set_string("formspec", formspec_main(tubelib.RUNNING, fs_data, sOUTPUT))
----			end
----		end
----	-- THIRD: evaluate edit events from sub-menus
--	elseif fields._col_ == "cond" then
--		local row = tonumber(fields._row_ or 1)
--		fs_data["cond"..row] = smartline.cond_eval_input(fs_data["cond"..row], fields)
--		meta:set_string("formspec", smartline.cond_formspec(row, fs_data["cond"..row]))
--		meta:set_string("fs_data", minetest.serialize(fs_data))
--	elseif fields._type_ == "main" then
--		fs_data = eval_formspec_main(meta, fs_data, fields, readonly)
--		meta:set_string("fs_data", minetest.serialize(fs_data))
----	elseif fields._type_ == "label" then
----		fs_data = eval_formspec_label(meta, fs_data, fields, readonly)
----		meta:set_string("fs_data", minetest.serialize(fs_data))
----	elseif fields._type_ == "cond" then
----		fs_data = eval_formspec_cond(meta, fs_data, fields, readonly)
----		meta:set_string("fs_data", minetest.serialize(fs_data))
----	elseif fields._type_ == "oprnd" then
----		fs_data = eval_formspec_oprnd(meta, fs_data, fields, readonly)
----		meta:set_string("fs_data", minetest.serialize(fs_data))
----	elseif fields._type_ == "actn" then
----		fs_data = eval_formspec_actn(meta, fs_data, fields, readonly)
----		meta:set_string("fs_data", minetest.serialize(fs_data))
----	elseif fields._type_ == "help" then
----		meta:set_string("formspec", formspec_main(state, fs_data, sOUTPUT))
----	elseif fields._type_ == "state" then
----		meta:set_string("formspec", formspec_main(state, fs_data, sOUTPUT))
--	end
--	-- FOURTH: back to main menu
--	if fields._exit_ then
--		meta:set_string("formspec", formspec_main(state, fs_data, sOUTPUT))
--	end
--end

--function smartline.on_receive_fields(pos, formname, fields, player)
--	local meta = minetest.get_meta(pos)
--	local owner = meta:get_string("owner")
--	if not player or not player:is_player() then
--		return
--	end
--	local readonly = player:get_player_name() ~= owner
	
--	print("fields", dump(fields))
	
--	if fields.cancel == nil then
--		if fields.rules then
--			--meta:set_string("rules", fields.rules)
--			meta:set_string("formspec", smartline.formspecRules(meta))
--		elseif fields.notes then
--			meta:set_string("notes", fields.notes)
--			meta:set_string("formspec", formspecNotes(meta))
--		end	
--	end
	
--	if fields.update then
--		meta:set_string("formspec", formspecOutput(meta))
--	elseif fields.clear then
--		meta:set_string("output", "<press update>")
--		meta:set_string("formspec", formspecOutput(meta))
--	elseif fields.tab == "1" then
--		meta:set_string("formspec", smartline.formspecRules(meta))
--	elseif fields.tab == "2" then
--		meta:set_string("formspec", formspecOutput(meta))
--	elseif fields.tab == "3" then
--		meta:set_string("formspec", formspecNotes(meta))
--	elseif fields.tab == "4" then
--		meta:set_string("formspec", formspecHelp(1))
--	elseif fields.start == "Start" then
--		start_controller(pos)
--		minetest.log("action", player:get_player_name() ..
--			" starts the sl_controller at ".. minetest.pos_to_string(pos))
--	elseif fields.stop == "Stop" then
--		stop_controller(pos)
--	end
--end


