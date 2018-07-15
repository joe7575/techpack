--[[

	sl_robot
	========

	Copyright (C) 2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	commands.lua:
	
	Register all robot commands

]]--


sl_robot.register_action("get_ms_time", {
	cmnd = function(self)
		return math.floor(minetest.get_us_time() / 1000)
	end,
	help = "$get_ms_time()\n"..
		" returns time with millisecond precision."
})

sl_robot.register_action("forward", {
	cmnd = function(self, steps)
		steps = tonumber(steps or 1)
		local idx = 1
		while idx <= steps do
			local meta = minetest.get_meta(self.meta.pos)
			local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
			local robot_param2 = meta:get_int("robot_param2")
			local new_pos = sl_robot.move_robot(robot_pos, robot_param2, 1)
			if new_pos then  -- not blocked?
				if new_pos.y == robot_pos.y then  -- forward move?
					idx = idx + 1
				end
				meta:set_string("robot_pos", minetest.pos_to_string(new_pos))
				--minetest.log("action", "[robby] forward "..meta:get_string("robot_pos"))
			end
			coroutine.yield()
		end
	end,
	help = "tbd"
})

sl_robot.register_action("left", {
	cmnd = function(self)
		local meta = minetest.get_meta(self.meta.pos)
		local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
		local robot_param2 = meta:get_int("robot_param2")
		robot_param2 = sl_robot.turn_robot(robot_pos, robot_param2, "L")
		meta:set_int("robot_param2", robot_param2)
		--minetest.log("action", "[robby] left "..meta:get_string("robot_pos"))
		coroutine.yield()
	end,
	help = "tbd"
})

sl_robot.register_action("right", {
	cmnd = function(self)
		local meta = minetest.get_meta(self.meta.pos)
		local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
		local robot_param2 = meta:get_int("robot_param2")
		robot_param2 = sl_robot.turn_robot(robot_pos, robot_param2, "R")
		meta:set_int("robot_param2", robot_param2)
		--minetest.log("action", "[robby] right "..meta:get_string("robot_pos"))
		coroutine.yield()
	end,
	help = "tbd"
})

sl_robot.register_action("up", {
	cmnd = function(self)
		local meta = minetest.get_meta(self.meta.pos)
		local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
		local robot_param2 = meta:get_int("robot_param2")
		local new_pos
		while true do
			new_pos = sl_robot.robot_up(robot_pos, robot_param2)
			if new_pos then break end
			coroutine.yield()
		end
		meta:set_string("robot_pos", minetest.pos_to_string(new_pos))
		--minetest.log("action", "[robby] up "..meta:get_string("robot_pos"))
		coroutine.yield()
	end,
	help = "tbd"
})

sl_robot.register_action("down", {
	cmnd = function(self)
		local meta = minetest.get_meta(self.meta.pos)
		local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
		local robot_param2 = meta:get_int("robot_param2")
		local new_pos
		while true do
			new_pos = sl_robot.robot_down(robot_pos, robot_param2)
			if new_pos then break end
			coroutine.yield()
		end
		meta:set_string("robot_pos", minetest.pos_to_string(new_pos))
		--minetest.log("action", "[robby] down "..meta:get_string("robot_pos"))
		coroutine.yield()
	end,
	help = "tbd"
})

sl_robot.register_action("take", {
	cmnd = function(self, num, slot)
		local meta = minetest.get_meta(self.meta.pos)
		local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
		local robot_param2 = meta:get_int("robot_param2")
		sl_robot.robot_take(self.meta.pos, robot_pos, robot_param2, self.meta.owner, num, slot)
		minetest.log("action", "[robby] take "..meta:get_string("robot_pos"))
		coroutine.yield()
	end,
	help = "take 'num' items from the nodes inventory\n"..
		"in front of the robot and put into the own 'slot'"
})

sl_robot.register_action("add", {
	cmnd = function(self, num, slot)
		local meta = minetest.get_meta(self.meta.pos)
		local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
		local robot_param2 = meta:get_int("robot_param2")
		sl_robot.robot_add(self.meta.pos, robot_pos, robot_param2, self.meta.owner, num, slot)
		minetest.log("action", "[robby] add "..meta:get_string("robot_pos"))
		coroutine.yield()
	end,
	help = "take 'num' items from the own 'slot' and\n"..
		"add to the nodes inventory in front of the robot"
})

sl_robot.register_action("stop", {
	cmnd = function(self)
		while true do
			coroutine.yield()
		end
	end,
	help = "tbd"
})

