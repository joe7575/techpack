gravelsieve = {
    -- Load support for I18n
    S = minetest.get_translator("gravelsieve"),

    version = "20210214.0",

    modname = minetest.get_current_modname(),
    modpath = minetest.get_modpath(minetest.get_current_modname()),

    log = function(level, message, ...)
        minetest.log(level, ("[%s] %s"):format(gravelsieve.modname, message:format(...)))
    end
}

gravelsieve.log("info", "loading gravelsieve mod...")

local function gs_dofile(filename)
    dofile(("%s/%s"):format(gravelsieve.modpath, filename))
end

if minetest.global_exists("unified_inventory") then
	unified_inventory.register_craft_type("sieving", {
		description = S("Sieving (by chance)"),
		icon = "gravelsieve_sieve.png",
		width = 1,
		height = 1,
	})
end

gs_dofile("settings.lua")
gs_dofile("api.lua")
gs_dofile("probability_api.lua")

gs_dofile("test.lua")

gs_dofile("sieve.lua")
gs_dofile("nodes.lua")
gs_dofile("hammer.lua")
gs_dofile("crafts.lua")

gs_dofile("default_output.lua")

gs_dofile("compat.lua")
gs_dofile("interop/hopper.lua")
gs_dofile("interop/moreblocks.lua")
gs_dofile("interop/tubelib.lua")
