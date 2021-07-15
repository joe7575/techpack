-- support for moreblock's circular saw
if not minetest.get_modpath("moreblocks") then
    return
end

local S = gravelsieve.S
stairsplus:register_all("gravelsieve", "compressed_gravel", "gravelsieve:compressed_gravel", {
    description = S("Compressed Gravel"),
    groups = { cracky = 2, crumbly = 2, choppy = 2, not_in_creative_inventory = 1 },
    tiles = { "gravelsieve_compressed_gravel.png" },
    sounds = default.node_sound_stone_defaults(),
})
