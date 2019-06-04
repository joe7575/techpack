minetest.register_node("tubelib:defect_dummy", {
	description = "Corrupted Tubelib Node",
	tiles = {
		"tubelib_front.png",
		"tubelib_front.png",
		"tubelib_front.png^tubelib_defect.png",
		"tubelib_front.png^tubelib_defect.png",
		"tubelib_front.png^tubelib_defect.png",
		"tubelib_front.png^tubelib_defect.png",
	},
	drop = "",
	groups = {cracky=3, crumbly=3, choppy=3, not_in_creative_inventory=1},
	is_ground_content = false,
})


function tubelib.data_not_corrupted(pos)	
	if minetest.pos_to_string(pos) ~= minetest.get_meta(pos):get_string("my_pos") then
		-- node number corrupt?
		local meta = minetest.get_meta(pos)
		local number = meta:get_string("tubelib_number")
		if number == "" then
			number = meta:get_string("number")
		end
		if number == "" then
			number = meta:get_string("own_num")
		end
		if number == "" then
			number = meta:get_string("own_number")
		end
		if number == "" then
			tubelib.remove_node(pos)
			minetest.set_node(pos, {name = "tubelib:defect_dummy"})
			meta:from_table(nil)
			return false
		end
		-- node moved?
		local info = tubelib.get_node_info(number)
		if not info or not vector.equals(info.pos, pos) then
			local node = minetest.get_node(pos)
			number = tubelib.get_new_number(pos, node.name)
			meta:set_string("tubelib_number", number)
--			tubelib.remove_node(pos)
--			minetest.set_node(pos, {name = "tubelib:defect_dummy"})
--			meta:from_table(nil)
--			return false
		end
		minetest.get_meta(pos):get_string("my_pos", minetest.pos_to_string(pos))
	end
	return true
end