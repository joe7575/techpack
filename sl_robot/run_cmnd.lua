--[[

	sl_robot
	========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	run_cmnd.lua:
	
	Register the run command

]]--

local function Reverse(arr)
	local i, j = 1, #arr

	while i < j do
		arr[i], arr[j] = arr[j], arr[i]

		i = i + 1
		j = j - 1
	end
end

local switch = {
	f = function(cmnd) 
		local num = (cmnd:byte(2) or  0x31) - 0x30
		print("forward("..num..")")
	end,
	b = function(cmnd) 
		local num = (cmnd:byte(2) or 0x31) - 0x30
		print("backward("..num..")")
	end,
	l = function(cmnd, reverse) 
		if reverse then
			print("right()")
		else
			print("left()")
		end
	end,
	r = function(cmnd, reverse) 
		if reverse then
			print("left()")
		else
			print("right()")
		end
	end,
	u = function(cmnd) 
		print("up()")
	end,
	d = function(cmnd) 
		print("down()")
	end,
	t = function(cmnd) 
		local num, slot
		if cmnd:sub(2,2) == "s" then
			num = 99
			slot = (cmnd:byte(3) or 0x31) - 0x30
		else
			num = 1
			slot = (cmnd:byte(2) or 0x31) - 0x30
		end
		print("take("..num..","..slot..")")
	end,
	a = function(cmnd) 
		local num, slot
		if cmnd:sub(2,2) == "s" then
			num = 99
			slot = (cmnd:byte(3) or 0x31) - 0x30
		else
			num = 1
			slot = (cmnd:byte(2) or 0x31) - 0x30
		end
		print("add("..num..","..slot..")")
	end,
	p = function(cmnd) 
		local num, slot
		if cmnd:sub(2,2) == "u" then
			slot = (cmnd:byte(3) or 0x31) - 0x30
			print("place("..slot..",U)")
		elseif cmnd:sub(2,2) == "d" then
			slot = (cmnd:byte(3) or 0x31) - 0x30
			print("place("..slot..",D)")
		else
			slot = (cmnd:byte(2) or 0x31) - 0x30
			print("place("..slot..")")
		end
	end,
	e = function(cmnd)
		print(cmnd.." is a invalid command")
	end,
}

local function run(task, reverse)
	task = task:gsub("\n", " ")
	task = task:gsub("\t", " ")
	local cmnds = task:split(" ")
	if reverse then
		Reverse(cmnds)
	end
	for i,cmnd in ipairs(cmnds) do
		(switch[cmnd:sub(1,1)] or switch["e"])(cmnd, reverse)
	end
end

sl_robot.register_action("run", {
	cmnd = function(self, sCmndList, reverse)
		sCmndList = sCmndList:gsub("\n", " ")
		sCmndList = sCmndList:gsub("\t", " ")
		local cmnds = sCmndList:split(" ")
		if reverse then
			Reverse(cmnds)
		end
		for i,cmnd in ipairs(cmnds) do
			(switch[cmnd:sub(1,1)] or switch["e"])(cmnd, reverse)
		end
	end,
	help = " "
})
