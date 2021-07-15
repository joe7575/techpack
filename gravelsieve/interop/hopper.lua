-- support for hopper
if not minetest.get_modpath("hopper") or not hopper or not hopper.add_container then
    return
end

hopper:add_container({
    { "bottom", "gravelsieve:auto_sieve0", "src" },
    { "top", "gravelsieve:auto_sieve0", "dst" },
    { "side", "gravelsieve:auto_sieve0", "src" },

    { "bottom", "gravelsieve:auto_sieve1", "src" },
    { "top", "gravelsieve:auto_sieve1", "dst" },
    { "side", "gravelsieve:auto_sieve1", "src" },

    { "bottom", "gravelsieve:auto_sieve2", "src" },
    { "top", "gravelsieve:auto_sieve2", "dst" },
    { "side", "gravelsieve:auto_sieve2", "src" },

    { "bottom", "gravelsieve:auto_sieve3", "src" },
    { "top", "gravelsieve:auto_sieve3", "dst" },
    { "side", "gravelsieve:auto_sieve3", "src" },
})
