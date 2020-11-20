-- Load support for I18n
local S = tubelib.S

minetest.register_node("tubelib:defect_dummy", {
	description = S("Corrupted Tubelib Node"),
	tiles = {
		"tubelib_front.png",
		"tubelib_front.png",
		"tubelib_front.png^tubelib_defect.png",
		"tubelib_front.png^tubelib_defect.png",
		"tubelib_front.png^tubelib_defect.png",
		"tubelib_front.png^tubelib_defect.png",
	},
	groups = {cracky=3, crumbly=3, choppy=3, not_in_creative_inventory=1},
	is_ground_content = false,
})

local reported_machines = {}
local function report(pos)
	reported_machines[minetest.pos_to_string(pos)] = true
end
local function already_reported(pos)
	local key = minetest.pos_to_string(pos)
	return reported_machines[key]
end


function tubelib.data_not_corrupted(pos, has_no_info)	
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
			if not already_reported(pos) then
				minetest.log('error', ('[tubelib] machine @ %s has no number'):format(minetest.pos_to_string(pos)))
				report(pos)
			end
		end
		
		-- button like odes
		if has_no_info then 
			minetest.get_meta(pos):get_string("my_pos", minetest.pos_to_string(pos))
			return true 
		end
		
		-- node moved?
		local info = tubelib.get_node_info(number)
		if not info or not vector.equals(info.pos, pos) then
			if not already_reported(pos) then
				if not info then
					minetest.log('error', ('[tubelib] machine @ %s has no info'):format(minetest.pos_to_string(pos)))
				else
					minetest.log('error', ('[tubelib] machine @ %s thinks it is at %s'):format(minetest.pos_to_string(pos), minetest.pos_to_string(info.pos)))
				end
				report(pos)
			end
			local node = minetest.get_node(pos)
			number = tubelib.get_new_number(pos, node.name)
			meta:set_string("tubelib_number", number)
		end
		minetest.get_meta(pos):get_string("my_pos", minetest.pos_to_string(pos))
	end
	return true
end
