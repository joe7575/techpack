-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

local Tube = tubelib.Tube

local TubesTranslation = {
	["tubelib:tube1"] = {[0]=
		{12, "S"},
		{21, "S"},
	},
	["tubelib:tube2"] = {[0]=
		{ 4, "S"},
	},
	["tubelib:tube3"] = {[0]=
		{ 5, "A"},
		{14, "A"},
		{11, "A"},
		{ 7, "A"},
	},
	["tubelib:tube4"] = {[0]=
		{ 0, "A"},
		{15, "A"},
		{ 8, "A"},
		{ 3, "A"},
	},
	["tubelib:tube5"] = {[0]=
		{20, "A"},
		{13, "A"},
		{10, "A"},
		{19, "A"},
	},
}

minetest.register_lbm({
	label = "[Tubelib] tubes migration",
	name = "tubelib:migrate",
	nodenames = {
		"tubelib:tube1",
		"tubelib:tube2",
		"tubelib:tube3",
		"tubelib:tube4",
		"tubelib:tube5",
		"tubelib_addons3:teleporter",
	},
	run_at_every_load = true,
	action = function(pos, node)
		if node.name == "tubelib_addons3:teleporter" then
			local meta = M(pos)
			local peer = meta:get_string("peer")
			if peer ~= "" then
				meta:set_string("tele_pos", peer)
				local peer_pos = P(peer)
				local _,node = Tube:get_node(peer_pos)
				local tube_dir = ((3 + (node.param2 % 4)) % 4) + 1
				print("migrate "..node.name.." at "..S(pos))
				meta:set_string("peer", nil)
				if tube_dir then
					meta:set_int("tube_dir", tube_dir)
				end
				tube_dir = Tube:get_primary_dir(pos)
				Tube:tool_repair_tube(Tube:get_pos(pos, tube_dir))
			end
		else
			local items = TubesTranslation[node.name][node.param2]
			if items then
				print("migrate "..node.name.." at "..S(pos))
				local param2, ntype = items[1], items[2]
				minetest.set_node(pos, {name = "tubelib:tube"..ntype, param2 = param2})
			end
		end
	end
})

minetest.register_node("tubelib:tube1", minetest.registered_nodes["tubelib:tubeS"])
