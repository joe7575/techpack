--[[

	ICTA Controller
	===============

	Part of the SmartLine mod
	
	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	condition.lua

]]--

local sl = smartline

-- tables with all data from condition registrations
local kvRegisteredCond = {}

-- list of keys for conditions
local aCondTypes = {}

-- list of titles for conditions
local aCondTitles = {}

--
-- API functions for condition registrations
--
function sl.icta_register_condition(key, tData)
	table.insert(aCondTypes, key)
	table.insert(aCondTitles, tData.title)
	if kvRegisteredCond[key] ~= nil then
		print("[SmartLine] Condition registration error "..key)
		return
	end
	kvRegisteredCond[key] = tData
	for _,item in ipairs(tData.formspec) do
		if item.type == "textlist" then
			item.tChoices = string.split(item.choices, ",")
			item.num_choices = #item.tChoices
		end
	end
end

-- return formspec string
function sl.cond_formspec(row, kvSelect)
	return sl.submenu_generate_formspec(
		row, "cond", "Condition type", aCondTypes, aCondTitles, kvRegisteredCond, kvSelect)
end	
	
-- evaluate the row condition input
-- and return new data
function sl.cond_eval_input(kvSelect, fields)
	kvSelect = sl.submenu_eval_input(kvRegisteredCond, aCondTypes, aCondTitles, kvSelect, fields)
	return kvSelect
end
	
-- return the Lua code	
function sl.code_condition(kvSelect, environ)
	if kvSelect and kvRegisteredCond[kvSelect.choice] then
		if smartline.submenu_verify(kvRegisteredCond, kvSelect) then
			return kvRegisteredCond[kvSelect.choice].code(kvSelect, environ)
		end
	end
	return nil, nil
end

sl.icta_register_condition("default", {
	title = "",
	formspec = {},
	code = function(data, environ) return false, false end,
	button = function(data, environ) return "..." end,
})

