local bottoms_by_top = {
	["tubelib_addons1:fermenter_top"] = {"tubelib_addons1:fermenter", "tubelib_addons1:fermenter_defect"},
	["tubelib_addons1:reformer_top"] = {"tubelib_addons1:reformer", "tubelib_addons1:reformer_defect"},
}

local top_by_bottom = {
	["tubelib_addons1:fermenter"] = "tubelib_addons1:fermenter_top",
	["tubelib_addons1:fermenter_defect"] = "tubelib_addons1:fermenter_top",
	["tubelib_addons1:reformer"] = "tubelib_addons1:reformer_top",
	["tubelib_addons1:reformer_defect"] = "tubelib_addons1:reformer_top",
}

-- remove tops of multiblocks which aren't over the bottom; happens due to bugs or worldedit
minetest.register_lbm({
	label = "Remove detached tops of multiblocks",
	name = "tubelib_addons1:remove_detached_tops",
	nodenames = {
		"tubelib_addons1:fermenter_top",
		"tubelib_addons1:reformer_top",
	},
	run_at_every_load = true,
	action = function(pos, node)
		local bottoms = bottoms_by_top[node.name]
		local pos_under = vector.subtract(pos, vector.new(0, 1, 0))
		local node_under = minetest.get_node_or_nil(pos_under)

		if not node_under then
			-- not loaded
			return
		end

		local node_under_name = node_under.name

		for _, bottom in ipairs(bottoms) do
			if node_under_name == bottom then
				-- has an acceptable bottom
				return
			end
		end

		minetest.remove_node(pos)
	end
})

-- fix multiblocks with missing tops; happens due to bugs or worldedit
minetest.register_lbm({
	label = "Fix missing tops of multiblocks",
	name = "tubelib_addons1:fix_missing_tops",
	nodenames = {
		"tubelib_addons1:fermenter",
		"tubelib_addons1:fermenter_defect",
		"tubelib_addons1:reformer",
		"tubelib_addons1:reformer_defect",
	},
	run_at_every_load = true,
	action = function(pos, node)
		local pos_above = vector.add(pos, vector.new(0, 1, 0))
		local node_above = minetest.get_node(pos_above)

		if node_above.name ~= "air" then
			return
		end

		local top = top_by_bottom[node.name]
		minetest.add_node(pos_above, {name=top, param2=node.param2})
	end
})
