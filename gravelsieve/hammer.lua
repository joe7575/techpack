--[[

	Gravel Sieve Mod
	================

]]--


gravelsieve.disallow = function(pos, node, user, mode, new_param2)
	return false
end

gravelsieve.handler = function(itemstack, user, pointed_thing)
	if pointed_thing.type ~= "node" then
		return
	end

	local pos = pointed_thing.under

	if minetest.is_protected(pos, user:get_player_name()) then
		minetest.record_protection_violation(pos, user:get_player_name())
		return
	end

	local node = minetest.get_node(pos)
	if node.name == "default:cobble" or node.name == "default:mossycobble" 
			or node.name == "default:desert_cobble" then
		node.name = "default:gravel"
		minetest.swap_node(pos, node)
		minetest.sound_play({
			name="default_dig_crumbly"},{
			gain=1,
			pos=pos,
			max_hear_distance=6,
			loop=false})
	end

	itemstack:add_wear(65535 / (500 - 1))
	return itemstack
end

minetest.register_tool("gravelsieve:hammer", {
	description = "Hammer converts Cobblestone into Gravel",
	inventory_image = "gravelsieve_hammer.png",
	on_use = function(itemstack, user, pointed_thing)
		return gravelsieve.handler(itemstack, user, pointed_thing)
	end,
})

minetest.register_craft({
	output = "gravelsieve:hammer",
	recipe = {
		{"", "default:steel_ingot", ""},
		{"", "group:stick", "default:steel_ingot"},
		{"group:stick", "", ""},
	}
})

