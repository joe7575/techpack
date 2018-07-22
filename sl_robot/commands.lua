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
		steps = math.min(tonumber(steps or 1), 100)
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
	help = " go one (or more) steps forward\n"..
		" Syntax: $forward(<steps>)\n"..
		" Example: $forward(4)"
})

sl_robot.register_action("backward", {
	cmnd = function(self, steps)
		steps = math.min(tonumber(steps or 1), 100)
		local idx = 1
		while idx <= steps do
			local meta = minetest.get_meta(self.meta.pos)
			local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
			local robot_param2 = meta:get_int("robot_param2")
			local new_pos = sl_robot.move_robot(robot_pos, robot_param2, -1)
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
	help = " go one (or more) steps backward\n"..
		" Syntax: $backward(<steps>)\n"..
		" Example: $backward(4)"
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
	help = " turn left\n"..
		" Example: $left()"
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
	help = " turn right\n"..
		" Example: $right()"
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
	help = " go one step up (2 steps max.)\n"..
		" Example: $up()"
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
	help = " go down again (2 steps max.)\n"..
		" you have to go up before\n"..
		" Example: $down()"
})

sl_robot.register_action("take", {
	cmnd = function(self, num, slot)
		num = math.min(tonumber(num or 1), 99)
		slot = math.min(tonumber(slot or 1), 8)
		local meta = minetest.get_meta(self.meta.pos)
		local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
		local robot_param2 = meta:get_int("robot_param2")
		sl_robot.robot_take(self.meta.pos, robot_pos, robot_param2, self.meta.owner, num, slot)
		minetest.log("action", "[robby] take "..meta:get_string("robot_pos"))
		coroutine.yield()
	end,
	help = " take 'num' items from a chest or a node\n"..
		" with an inventory in front of the robot\n"..
		" and put the item into the own inventory,\n"..
		" specified by 'slot'.\n"..
		" Syntax: $take(num, slot)\n"..
		" Example: $take(99, 1)"
})

sl_robot.register_action("add", {
	cmnd = function(self, num, slot)
		num = math.min(tonumber(num or 1), 99)
		slot = math.min(tonumber(slot or 1), 8)
		local meta = minetest.get_meta(self.meta.pos)
		local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
		local robot_param2 = meta:get_int("robot_param2")
		sl_robot.robot_add(self.meta.pos, robot_pos, robot_param2, self.meta.owner, num, slot)
		minetest.log("action", "[robby] add "..meta:get_string("robot_pos"))
		coroutine.yield()
	end,
	help = " take 'num' items from the own inventory\n"..
		" specified by 'slot' and add it to the nodes\n"..
		" inventory in front of the robot.\n"..
		" Syntax: $add(num, slot)\n"..
		" Example: $add(99, 1)"
})

sl_robot.register_action("place", {
	cmnd = function(self, slot, dir)
		slot = math.min(tonumber(slot or 1), 8)
		local meta = minetest.get_meta(self.meta.pos)
		local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
		local robot_param2 = meta:get_int("robot_param2")
		sl_robot.robot_place(self.meta.pos, robot_pos, robot_param2, self.meta.owner, dir, slot)
		minetest.log("action", "[robby] place "..meta:get_string("robot_pos"))
		coroutine.yield()
	end,
	help = " places an node in front of, above (up),\n"..
		"  or below (down) the robot. The node is taken\n"..
		" from the own inventory, specified by 'slot'.\n"..
		' Examples: $place(1) $place(1, "U"), $place(1, "D")'
})

sl_robot.register_action("dig", {
	cmnd = function(self, slot, dir)
		slot = math.min(tonumber(slot or 1), 8)
		local meta = minetest.get_meta(self.meta.pos)
		local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
		local robot_param2 = meta:get_int("robot_param2")
		sl_robot.robot_dig(self.meta.pos, robot_pos, robot_param2, self.meta.owner, dir, slot)
		minetest.log("action", "[robby] dig "..meta:get_string("robot_pos"))
		coroutine.yield()
	end,
	help = " dig an node in front of, above (up),\n"..
		"  or below (down) the robot. The node is placed\n"..
		" into the own inventory, specified by 'slot'.\n"..
		' Examples: $dig(1) $dig(1, "U"), $dig(1, "D")'
})

sl_robot.register_action("stop", {
	cmnd = function(self)
		while true do
			coroutine.yield()
		end
	end,
	help = "tbd"
})

--sl_robot.register_action("run", {
--	cmnd = function(self, sCmd, reverse)
--		slot = math.min(tonumber(slot or 1), 8)
--		local meta = minetest.get_meta(self.meta.pos)
--		local robot_pos = minetest.string_to_pos(meta:get_string("robot_pos"))
--		local robot_param2 = meta:get_int("robot_param2")
		
--		for cmnd in sCmd:gmatch("%w+") do
--			if cmnd:byte()
--		end
--	end,
--	help = " "
--})
