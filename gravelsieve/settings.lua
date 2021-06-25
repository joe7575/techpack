gravelsieve.settings = {}

local settings_get
if minetest.setting_get then
	settings_get = minetest.setting_get
else
	settings_get = function(...) return minetest.settings:get(...) end
end

gravelsieve.settings.step_delay = tonumber(settings_get("gravelsieve.step_delay")) or 1.0
gravelsieve.settings.ore_max_elevation = tonumber(settings_get("gravelsieve.ore_max_elevation")) or tonumber(settings_get("gravelsieve_ore_max_elevation")) or 0
gravelsieve.settings.ore_min_elevation = tonumber(settings_get("gravelsieve.ore_min_elevation")) or tonumber(settings_get("gravelsieve_ore_min_elevation")) or -30912

-- Need to do weird logic to account for both factors being combined in legacy version
local ore_rarity = settings_get("gravelsieve.ore_rarity")
local legacy_ore_rarity = settings_get("gravelsieve_ore_rarity")
gravelsieve.settings.ore_rarity = 1.16 / 3.0
if ore_rarity then
	gravelsieve.settings.ore_rarity = tonumber(ore_rarity)
elseif legacy_ore_rarity then
	gravelsieve.settings.ore_rarity = tonumber(legacy_ore_rarity) / 3.0
end

-- tubelib aging feature
if minetest.get_modpath("tubelib") and tubelib ~= nil then
    gravelsieve.settings.aging_level1 = 15 * tubelib.machine_aging_value
    gravelsieve.settings.aging_level2 = 60 * tubelib.machine_aging_value
end

