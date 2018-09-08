--[[

	ICTA Controller
	===============

	Part of the SmartLine mod
	
	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	balancer.lua
	
]]--

local MAX_DIFF = 10

function smartline.balancer_condition(number1, number2, ratio1, ratio2, owner)
	local cnt1 = tubelib.send_request(number1, "counter", nil) / ratio1
	local cnt2 = tubelib.send_request(number2, "counter", nil) / ratio2
	if cnt1 > cnt2 + MAX_DIFF then
		tubelib.send_message(number1, owner, nil, "off", nil)
		return number1
	elseif cnt2 > cnt1 + MAX_DIFF then
		tubelib.send_message(number2, owner, nil, "off", nil)
		return number2
	end
end

smartline.icta_register_condition("ratio", {
	title = "balancer ratio",
	formspec = {
		{
			type = "numbers", 
			name = "number1", 
			label = "Pusher1 number", 
			default = "",
		},
		{
			type = "digits", 
			name = "ratio1", 
			label = "Ratio1 value", 
			default = "",
		},
		{
			type = "numbers", 
			name = "number2", 
			label = "Pusher2 number", 
			default = "",
		},
		{
			type = "digits", 
			name = "ratio2", 
			label = "Ratio1 value", 
			default = "",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Pusher1:Pusher2 shall have an\nitem counter ratio of Ratio1:Ratio2.", 
		},
	},
	-- Return two chunks of executable Lua code for the controller, according:
	--    return <read condition>, <expected result>
	code = function(data, environ)
		local s = 'smartline.balancer_condition("%s", "%s", %s, %s, "%s")'
		return s:format(data.number1, data.number2, data.ratio1, data.ratio2, environ.owner), '~= nil'
	end,
	button = function(data, environ) 
		return "ratio("..smartline.fmt_number(data.number1)..","..
			smartline.fmt_number(data.number2)..","..data.ratio1..":"..data.ratio2..')'
	end,
})

smartline.icta_register_action("balancer", {
	title = "balancer action",
	formspec = {
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Action part of the balancer rule.", 
		},
	},
	button = function(data, environ) 
		return 'balancer()'
	end,
	code = function(data, environ)
		local s = 'tubelib.send_message(env.result[#], "%s", nil, "on", nil)'
		return string.format(s, data.number, environ.owner)
	end,
})

smartline.icta_register_action("clearcounter", {
	title = "balancer clear counter",
	formspec = {
		{
			type = "numbers", 
			name = "number1", 
			label = "Pusher1 number", 
			default = "",
		},
		{
			type = "numbers", 
			name = "number2", 
			label = "Pusher2 number", 
			default = "",
		},
		{
			type = "label", 
			name = "lbl", 
			label = "Hint: Clear both Pusher counters\ne.g. after controller start.", 
		},
	},
	button = function(data, environ) 
		return 'clear cnt('..smartline.fmt_number(data.number1)..","..
			smartline.fmt_number(data.number2)..')'
	end,
	code = function(data, environ)
		local s = [[tubelib.send_message("%s", "%s", nil, "clear_counter", nil)
			tubelib.send_message("%s", "%s", nil, "clear_counter", nil)]]
		return string.format(s, data.number1, environ.owner, data.number2, environ.owner)
	end,
})

