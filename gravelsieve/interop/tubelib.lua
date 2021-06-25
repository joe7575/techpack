------------------------------------------------------------------------
-- Optional adaption to tubelib
------------------------------------------------------------------------
if not minetest.global_exists("tubelib") then
    return
end

local settings = gravelsieve.settings

minetest.register_node("gravelsieve:sieve_defect", {
    tiles = {
        -- up, down, right, left, back, front
        "gravelsieve_top.png",
        "gravelsieve_gravel.png",
        "gravelsieve_auto_sieve.png^tubelib_defect.png",
    },
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {
            { -8 / 16, -8 / 16, -8 / 16, 8 / 16, 4 / 16, -6 / 16 },
            { -8 / 16, -8 / 16, 6 / 16, 8 / 16, 4 / 16, 8 / 16 },
            { -8 / 16, -8 / 16, -8 / 16, -6 / 16, 4 / 16, 8 / 16 },
            { 6 / 16, -8 / 16, -8 / 16, 8 / 16, 4 / 16, 8 / 16 },
            { -6 / 16, -2 / 16, -6 / 16, 6 / 16, 2 / 16, 6 / 16 },
        },
    },
    selection_box = {
        type = "fixed",
        fixed = { -8 / 16, -8 / 16, -8 / 16, 8 / 16, 4 / 16, 8 / 16 },
    },

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_int("idx", 0)        -- for the 4 sieve phases
        meta:set_int("gravel_cnt", 0)   -- counter to switch between gravel and sieved gravel
        meta:set_string("node_name", "gravelsieve:auto_sieve")
        meta:set_string("formspec", sieve_formspec)
        local inv = meta:get_inventory()
        inv:set_size('src', 1)
        inv:set_size('dst', 16)
    end,

    after_place_node = function(pos, placer)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", S("Gravel Sieve"))
        meta:set_string("player_name", placer:get_player_name())
        gravelsieve.api.count.add(pos, placer)
    end,

    on_dig = function(pos, node, puncher, pointed_thing)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        if inv:is_empty("dst") and inv:is_empty("src") then
            minetest.node_dig(pos, node, puncher, pointed_thing)
        end
    end,
    after_dig_node = function (pos, oldnode, oldmetadata, digger)
        gravelsieve.api.count.del(pos, digger)
    end,

    paramtype = "light",
    sounds = default.node_sound_wood_defaults(),
    paramtype2 = "facedir",
    sunlight_propagates = true,
    is_ground_content = false,
    groups = { choppy = 2, cracky = 1, not_in_creative_inventory = 1 },
})

tubelib.register_node("gravelsieve:auto_sieve3",
    {
        "gravelsieve:auto_sieve0",
        "gravelsieve:auto_sieve1",
        "gravelsieve:auto_sieve2",
        "gravelsieve:sieve_defect",
    },
    {
        on_pull_item = function(pos, side)
            local meta = minetest.get_meta(pos)
            return tubelib.get_item(meta, "dst")
        end,
        on_push_item = function(pos, side, item)
            minetest.get_node_timer(pos):start(settings.step_delay)
            local meta = minetest.get_meta(pos)
            return tubelib.put_item(meta, "src", item)
        end,
        on_unpull_item = function(pos, side, item)
            local meta = minetest.get_meta(pos)
            return tubelib.put_item(meta, "dst", item)
        end,
        on_node_load = function(pos)
            minetest.get_node_timer(pos):start(settings.step_delay)
        end,
        on_node_repair = function(pos)
            local meta = minetest.get_meta(pos)
            meta:set_int("tubelib_aging", 0)
            meta:set_int("idx", 2)
            meta:set_string("node_name", "gravelsieve:auto_sieve")
            local inv = meta:get_inventory()
            inv:set_size('src', 1)
            inv:set_size('dst', 16)
            gravelsieve.sieve.step_node(pos, meta, false)
            minetest.get_node_timer(pos):start(settings.step_delay)
            return true
        end,
    }
)
