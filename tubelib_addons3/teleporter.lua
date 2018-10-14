--[[

	Tubelib Addons 3
	================

	Copyright (C) 2017-2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	teleporter.lua
	
	A node, moving items to the peer teleporter node.

]]--

local PairingList = {}

local sForm = "size[7.5,3]"..
	"field[0.5,1;7,1;channel;Enter channel string;]" ..
	"button_exit[2,2;3,1;exit;Save]"

local function pairing(pos, channel)
	if PairingList[channel] and not vector.equals(pos, PairingList[channel]) then
		-- store peer position on both nodes
		local meta1 = minetest.get_meta(pos)
		local peer = minetest.pos_to_string(PairingList[channel])
		meta1:set_string("peer", peer)
		meta1:set_string("infotext", "Tubelib Teleporter, connected "..peer)
		meta1:set_string("channel", nil)
		meta1:set_string("formspec", nil)
		
		local meta2 = minetest.get_meta(PairingList[channel])
		local peer = minetest.pos_to_string(pos)
		meta2:set_string("peer", peer)
		meta2:set_string("infotext", "Tubelib Teleporter, connected "..peer)
		meta2:set_string("channel", nil)
		meta2:set_string("formspec", nil)
		
		PairingList[channel] = nil
		return true
	else
		PairingList[channel] = pos
		minetest.get_meta(pos):set_string("channel", channel)
		return false
	end
end

minetest.register_node("tubelib_addons3:teleporter", {
	description = "Tubelib Teleporter",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_addons3_chest_bottom.png',
		'tubelib_addons3_chest_bottom.png',
		'tubelib_addons3_chest_bottom.png^tubelib_hole.png',
		'tubelib_addons3_chest_bottom.png^tubelib_addons3_teleporter.png',
		'tubelib_addons3_chest_bottom.png^tubelib_addons3_teleporter.png',
		'tubelib_addons3_chest_bottom.png^tubelib_addons3_teleporter.png',
	},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		tubelib.add_node(pos, "tubelib_addons3:teleporter")
		meta:set_string("formspec", sForm)
		meta:set_string("infotext", "Tubelib Teleporter, unconfigured")
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local meta = minetest.get_meta(pos)
		if fields.channel ~= nil then
			if not pairing(pos, fields.channel) then
				meta:set_string("formspec", "size[7.5,3]"..
				"field[0.5,1;7,1;channel;Enter channel string;"..fields.channel.."]" ..
				"button_exit[2,2;3,1;exit;Save]")
			else
				local peer_pos = minetest.string_to_pos(meta:get_string("peer"))
				minetest.log("action", player:get_player_name()..
					" pairs Tubelib Teleporter nodes at "..
					minetest.pos_to_string(pos)..
					" and at "..minetest.pos_to_string(peer_pos))
			end
		end
	end,
	
	on_destruct = function(pos)
		-- unpair peer node
		local meta = minetest.get_meta(pos)
		local peer = meta:get_string("peer")
		if peer ~= "" then
			local peer_pos = minetest.string_to_pos(peer)
			local peer_meta = minetest.get_meta(peer_pos)
			peer_meta:set_string("channel", nil)
			peer_meta:set_string("peer", nil)
			peer_meta:set_string("formspec", sForm)
			peer_meta:set_string("infotext", "Tubelib Teleporter, unconfigured")
		end
	end,
	
	on_rotate = screwdriver.disallow,
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_craft({
	output = "tubelib_addons3:teleporter 2",
	recipe = {
		{"default:gold_ingot", "group:wood", ""},
		{"default:mese_crystal", "default:mese_crystal", "tubelib:tube1"},
		{"default:gold_ingot", "group:wood", ""},
	},
})

-- recursion detection
local LastPeerPos = nil

tubelib.register_node("tubelib_addons3:teleporter", {}, {
	on_push_item = function(pos, side, item)
		-- push on peer side
		local meta = minetest.get_meta(pos)
		local peer = meta:get_string("peer")
		if peer ~= "" and peer ~= LastPeerPos then
			LastPeerPos = peer
			local res = tubelib.push_items(minetest.string_to_pos(peer), "R", item, nil)
			LastPeerPos = nil
			return res
		end
		return false
	end,
	is_pusher = true,
})	

