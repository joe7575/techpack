--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	legacy_nodes.lua:
	
	Tubelib support for chests and furnace
	
]]--

tubelib.register_node("default:chest", {"default:chest_open"}, {
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		return tubelib.get_item(meta, "main")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
})	


tubelib.register_node("default:chest_locked", {"default:chest_locked_open"}, {
	on_pull_item = function(pos, side, player_name)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		if player_name == owner or player_name == "" then
			return tubelib.get_item(meta, "main")
		end
		return nil
	end,
	on_push_item = function(pos, side, item, player_name)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		if player_name == owner or player_name == "" then
			return tubelib.put_item(meta, "main", item)
		end
		return false
	end,
	on_unpull_item = function(pos, side, item, player_name)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		if player_name == owner or player_name == "" then
			return tubelib.put_item(meta, "main", item)
		end
		return nil
	end,
})	

tubelib.register_node("default:furnace", {"default:furnace_active"}, {
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		return tubelib.get_item(meta, "dst")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		minetest.get_node_timer(pos):start(1.0)
		if minetest.get_craft_result({method="fuel", width=1, items={item}}).time ~= 0 then
			return tubelib.put_item(meta, "fuel", item)
		else
			return tubelib.put_item(meta, "src", item)
		end
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "dst", item)
	end,
})	

tubelib.register_node("shop:shop", {}, {
	on_pull_item = function(pos, side, player_name)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		if player_name == owner or player_name == "" then
			return tubelib.get_item(meta, "register")
		end
		return nil
	end,
	on_push_item = function(pos, side, item, player_name)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		if player_name == owner or player_name == "" then
			return tubelib.put_item(meta, "stock", item)
		end
		return false
	end,
	on_unpull_item = function(pos, side, item, player_name)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		if player_name == owner or player_name == "" then
			return tubelib.put_item(meta, "register", item)
		end
		return nil
	end,
})	

tubelib.register_node("signs_bot:box", {}, {
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		return tubelib.get_item(meta, "main")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
})	

tubelib.register_node("signs_bot:chest", {}, {
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		return tubelib.get_item(meta, "main")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
})	
