minetest.register_craft({
    output = "gravelsieve:hammer",
    recipe = {
        { "", "default:steel_ingot", "" },
        { "", "group:stick", "default:steel_ingot" },
        { "group:stick", "", "" },
    }
})

minetest.register_craft({
    output = "gravelsieve:sieve",
    recipe = {
        { "group:wood", "", "group:wood" },
        { "group:wood", "default:steel_ingot", "group:wood" },
        { "group:wood", "", "group:wood" },
    },
})

minetest.register_craft({
    output = "gravelsieve:auto_sieve",
    type = "shapeless",
    recipe = {
        "gravelsieve:sieve", "default:mese_crystal", "default:mese_crystal",
    },
})

minetest.register_craft({
    output = "gravelsieve:compressed_gravel",
    recipe = {
        { "gravelsieve:sieved_gravel", "gravelsieve:sieved_gravel" },
        { "gravelsieve:sieved_gravel", "gravelsieve:sieved_gravel" },
    },
})

minetest.register_craft({
    type = "cooking",
    output = "default:cobble",
    recipe = "gravelsieve:compressed_gravel",
    cooktime = 10,
})
