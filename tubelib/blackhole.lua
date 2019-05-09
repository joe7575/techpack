--[[

	Tube Library
	============

	Copyright (C) 2017-2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	blackhole.lua:
	
	Simple node which lets all items disappear.
	The blackhole supports the following message:
	- topic = "status", payload  = nil, 
	  response is the number of disappeared items (0..n)
]]--

--                 +--------+
--                /        /|
--               +--------+ |
--     IN (L) -->|  BLACK | |          
--               |  HOLE  | +
--               |        |/
--               +--------+


minetest.register_node("tubelib:blackhole", {
	description = "Tubelib Black Hole",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_black_hole.png',
		'tubelib_black_hole_inp.png',
		"tubelib_black_hole.png",
		"tubelib_black_hole.png",
	},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local number = tubelib.add_node(pos, "tubelib:blackhole") -- <<=== tubelib
		meta:set_string("number", number)
		meta:set_int("disappeared", 0)
		meta:set_string("infotext","0 items disappeared")
	end,

	after_dig_node = function(pos)
		tubelib.remove_node(pos) -- <<=== tubelib
	end,

	on_rotate = screwdriver.disallow,
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})



minetest.register_craft({
	output = "tubelib:blackhole 2",
	recipe = {
		{"group:wood",    "",                   "group:wood"},
		{"tubelib:tubeS", "default:coal_lump",  "default:coal_lump"},
		{"group:wood",    "",                   "group:wood"},
	},
})

--------------------------------------------------------------- tubelib
tubelib.register_node("tubelib:blackhole", {}, {
	on_pull_item = nil,  		-- not needed
	on_unpull_item = nil,		-- not needed
	
	on_push_item = function(pos, side, item)
		if side == "L" then
			local meta = minetest.get_meta(pos)
			local disappeared = meta:get_int("disappeared") + item:get_count()
			meta:set_int("disappeared", disappeared)
			meta:set_string("infotext", disappeared.." items disappeared")
			return true		
		end
		return false
	end,
	
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "state" then
			local meta = minetest.get_meta(pos)
			return meta:get_int("disappeared")
		else
			return "not supported"
		end
	end,
})	
--------------------------------------------------------------- tubelib
