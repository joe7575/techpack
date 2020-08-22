local bottoms_by_node = {
    ["tubelib_addons1:fermenter_top"] = {"tubelib_addons1:fermenter", "tubelib_addons1:fermenter_defect"},
    ["tubelib_addons1:reformer_top"] = {"tubelib_addons1:reformer", "tubelib_addons1:reformer_defect"},
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
        local bottoms = bottoms_by_node[node.name]
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
