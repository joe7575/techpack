local S = gravelsieve.S

minetest.register_node("gravelsieve:sieved_gravel", {
    description = S("Sieved Gravel"),
    tiles = { "default_gravel.png" },
    groups = { crumbly = 2, falling_node = 1, not_in_creative_inventory = 1 },
    sounds = default.node_sound_gravel_defaults(),
})

minetest.register_node("gravelsieve:compressed_gravel", {
    description = S("Compressed Gravel"),
    tiles = { "gravelsieve_compressed_gravel.png" },
    groups = { cracky = 2, crumbly = 2, cracky = 2 },
    sounds = default.node_sound_gravel_defaults(),
})
