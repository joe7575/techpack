--[[

	Tubelib Addons 1
	================

	Copyright (C) 2017,2018 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

tubelib_addons1 = {}

-- tables needed for Harvester
tubelib_addons1.FarmingNodes = {}
tubelib_addons1.Flowers = {}

-- table needed for Grinder
tubelib_addons1.GroundNodes = {}


-- default trees which require the node timer
function tubelib_addons1.register_tree_node(name, drop, plant)
	tubelib_addons1.FarmingNodes[name] = {drop = drop or name, plant = plant, t1= 166, t2 = 288}
end

-- default farming nodes which require the node timer
function tubelib_addons1.register_default_farming_node(name, drop, plant)
	tubelib_addons1.FarmingNodes[name] = {drop = drop or name, plant = plant, t1 = 2400, t2 = 4800}
end

function tubelib_addons1.register_flower(name)
	tubelib_addons1.FarmingNodes[name] = {drop = name}
end

-- farming nodes with ABM
function tubelib_addons1.register_farming_node(name, drop, plant)
	tubelib_addons1.FarmingNodes[name] = {drop = drop or name, plant = plant}
	tubelib_addons1.FarmingNodes[name].leaves = string.find(name, "leaves") ~= nil
end

function tubelib_addons1.register_ground_node(name, drop)
	tubelib_addons1.GroundNodes[name] = {drop = drop or name}
end

local tn = tubelib_addons1.register_tree_node
local dn = tubelib_addons1.register_default_farming_node
local fn = tubelib_addons1.register_farming_node
local gn = tubelib_addons1.register_ground_node
local gr = tubelib.add_grinder_recipe

-------------------------------------------------------------------------------
-- Default Farming
-------------------------------------------------------------------------------
tn("default:tree",        "default:tree",        "default:sapling")
tn("default:aspen_tree",  "default:aspen_tree",  "default:aspen_sapling")
tn("default:pine_tree",   "default:pine_tree",   "default:pine_sapling")
tn("default:acacia_tree", "default:acacia_tree", "default:acacia_sapling")
tn("default:jungletree",  "default:jungletree",  "default:junglesapling")

fn("default:leaves")
fn("default:aspen_leaves")
fn("default:pine_needles")
tubelib_addons1.FarmingNodes["default:pine_needles"].leaves = true  -- accepted as leaves
fn("default:acacia_leaves")
fn("default:jungleleaves")

fn("default:bush_leaves")
fn("default:acacia_bush_leaves")

fn("default:cactus", "default:cactus", "default:cactus")
fn("default:papyrus", "default:papyrus", "default:papyrus")

fn("default:apple")

if farming.mod ~= "redo" then
	dn("farming:wheat_8",  "farming:wheat",  "farming:wheat_1")
	dn("farming:cotton_8", "farming:cotton", "farming:cotton_1")
end

-------------------------------------------------------------------------------
-- Farming Redo
-----------------------------------------------   --------------------------------
if farming.mod == "redo" then
	fn("farming:wheat_8",     "farming:wheat",          "farming:wheat_1")
	fn("farming:cotton_8",    "farming:cotton",         "farming:cotton_1")
	fn("farming:carrot_8",    "farming:carrot 2",       "farming:carrot_1")
	fn("farming:potato_4",    "farming:potato 3",       "farming:potato_1")
	fn("farming:tomato_8",    "farming:tomato 3",       "farming:tomato_1")
	fn("farming:cucumber_4",  "farming:cucumber 2",     "farming:cucumber_1")
	fn("farming:corn_8",      "farming:corn 2",         "farming:corn_1")
	fn("farming:coffee_5",    "farming:coffee_beans 2", "farming:coffee_1")
	fn("farming:melon_8",     "farming:melon_slice 4",  "farming:melon_1")
	fn("farming:pumpkin_8",   "farming:pumpkin_slice 4","farming:pumpkin_1")
	fn("farming:raspberry_4", "farming:raspberries",    "farming:raspberry_1")
	fn("farming:blueberry_4", "farming:blueberries",    "farming:blueberry_1")
	fn("farming:rhubarb_3",   "farming:rhubarb 2",      "farming:rhubarb_1")
	fn("farming:beanpole_5",  "farming:beans 3",        "farming:beanpole_1")
	fn("farming:grapes_8",    "farming:grapes 3",       "farming:grapes_1")
	fn("farming:barley_7",    "farming:barley",         "farming:barley_1")
	fn("farming:chili_8",     "farming:chili_pepper 2", "farming:chili_1")
	fn("farming:hemp_8",      "farming:hemp_leaf",      "farming:hemp_1")
	fn("farming:oat_8",       "farming:oat",            "farming:oat_1")
	fn("farming:rye_8",       "farming:rye",            "farming:rye_1")
	fn("farming:rice_8",      "farming:rice",           "farming:rice_1")
	fn('farming:beetroot_5',  'farming:beetroot 2',     'farming:beetroot_1')
	fn('farming:cocoa_4',     'farming:cocoa_beans 2',  'farming:cocoa_1')
	fn('farming:garlic_5',    'farming:garlic 2',       'farming:garlic_1')
	fn('farming:onion_5',     'farming:onion 2',        'farming:onion_1')
	fn('farming:pea_5',       'farming:pea_pod 3',      'farming:pea_1')
	fn('farming:pepper_5',    'farming:pepper 2',       'farming:pepper_1')
	fn('farming:pineapple_8', 'farming:pineapple 1',    'farming:pineapple_1')
end

-------------------------------------------------------------------------------
-- Ethereal Farming
-------------------------------------------------------------------------------
fn("ethereal:strawberry_8",   "ethereal:strawberry 2",	     "ethereal:strawberry 1")
fn("ethereal:onion_5",		  "ethereal:wild_onion_plant 2", "ethereal:onion_1")


fn("ethereal:willow_trunk",   "ethereal:willow_trunk", "ethereal:willow_sapling")
fn("ethereal:redwood_trunk",  "ethereal:redwood_trunk",  "ethereal:redwood_sapling")
fn("ethereal:frost_tree",     "ethereal:frost_tree",  "ethereal:frost_tree_sapling")
fn("ethereal:yellow_trunk",   "ethereal:yellow_trunk",  "ethereal:yellow_tree_sapling")
fn("ethereal:palm_trunk",     "ethereal:palm_trunk",  "ethereal:palm_sapling")
fn("ethereal:banana_trunk",   "ethereal:banana_trunk",  "ethereal:banana_tree_sapling")
fn("ethereal:mushroom_trunk", "ethereal:mushroom_trunk",  "ethereal:mushroom_sapling")
fn("ethereal:birch_trunk",    "ethereal:birch_trunk",  "ethereal:birch_sapling")
fn("ethereal:bamboo",         "ethereal:bamboo",       "ethereal:bamboo_sprout")

fn("ethereal:willow_twig")
fn("ethereal:redwood_leaves")
fn("ethereal:orange_leaves")
fn("ethereal:bananaleaves")
fn("ethereal:yellowleaves")
fn("ethereal:palmleaves")
fn("ethereal:birch_leaves")
fn("ethereal:frost_leaves")
fn("ethereal:bamboo_leaves")
fn("ethereal:mushroom")
fn("ethereal:mushroom_pore")
fn("ethereal:bamboo_leaves")
fn("ethereal:bamboo_leaves")
fn("ethereal:banana")
fn("ethereal:orange")
fn("ethereal:coconut")

-------------------------------------------------------------------------------
-- Default Ground
-------------------------------------------------------------------------------
gn("default:cobble")
gn("default:desert_cobble")
gn("default:mossycobble")
gn("default:gravel")
gn("default:dirt")
gn("default:sand")
gn("default:desert_sand")
gn("default:silver_sand")
gn("default:ice")
gn("default:snowblock")
gn("default:snow")
gn("default:obsidian")

gn("stairs:stair_cobble")
gn("stairs:stair_mossycobble")
gn("stairs:stair_desert_cobble")

gn("default:stone",             "default:cobble")
gn("default:desert_stone",      "default:desert_cobble")
gn("default:sandstone",         "default:sandstone")
gn("default:desert_sandstone",  "default:desert_sandstone")
gn("default:clay",              "default:clay_lump")
gn("default:stone_with_coal",   "default:coal_lump")
gn("default:stone_with_iron",   "default:iron_lump")
gn("default:stone_with_copper", "default:copper_lump")
gn("default:stone_with_gold",   "default:gold_lump")
gn("default:stone_with_tin",    "default:tin_lump")

gn("default:stone_with_mese",   "default:mese_crystal")

gn("default:stone_with_diamond",  "default:diamond")

gn("default:dirt_with_grass",             "default:dirt")
gn("default:dirt_with_grass_footsteps",   "default:dirt")
gn("default:dirt_with_dry_grass",         "default:dirt")
gn("default:dirt_with_snow",              "default:dirt")
gn("default:dirt_with_rainforest_litter", "default:dirt")
gn("default:dirt_with_grass",             "default:dirt")

gn("default:coral_skeleton",  "default:coral_skeleton")
gn("default:coral_orange",    "default:coral_skeleton")
gn("default:coral_brown",     "default:coral_skeleton")

-------------------------------------------------------------------------------
-- tubelib Ground
-------------------------------------------------------------------------------

gn("tubelib:basalt_stone",     "tubelib:basalt_stone")

-------------------------------------------------------------------------------
-- Moreores Ground
-------------------------------------------------------------------------------
gn("moreores:mineral_silver",     "moreores:silver_lump")
gn("moreores:mineral_mithril",    "moreores:mithril_lump")

-------------------------------------------------------------------------------
-- Farming Ground
-------------------------------------------------------------------------------
gn("farming:soil",     "default:dirt")
gn("farming:soil_wet", "default:dirt")

-------------------------------------------------------------------------------
-- Compost Ground
-------------------------------------------------------------------------------
gn("compost:garden_soil", "compost:garden_soil")

-------------------------------------------------------------------------------
-- Ethereal Ground
-------------------------------------------------------------------------------
gn("ethereal:dry_dirt",      "default:dirt")
gn("ethereal:bamboo_dirt",   "default:dirt")
gn("ethereal:jungle_dirt",   "default:dirt")
gn("ethereal:grove_dirt",    "default:dirt")
gn("ethereal:prairie_dirt",  "default:dirt")
gn("ethereal:cold_dirt",     "default:dirt")
gn("ethereal:crystal_dirt",  "default:dirt")
gn("ethereal:mushroom_dirt", "default:dirt")
gn("ethereal:fiery_dirt",    "default:dirt")
gn("ethereal:gray_dirt",     "default:dirt")
gn("ethereal:green_dirt",    "default:dirt")

gn("bakedclay:red",    "bakedclay:red")
gn("bakedclay:orange", "bakedclay:orange")
gn("bakedclay:grey",   "bakedclay:grey")

gn("ethereal:quicksand2", "default:sand")

gn("ethereal:illumishroom")
gn("ethereal:illumishroom2")
gn("ethereal:illumishroom3")


-------------------------------------------------------------------------------
-- Registered flowers
-------------------------------------------------------------------------------
local function register_flowers()
	for name,item in pairs(minetest.registered_items) do
		if item.groups.flower == 1 then
			tubelib_addons1.register_flower(name)
		end
	end
end

minetest.after(10, register_flowers)

-------------------------------------------------------------------------------
-- moretrees
-------------------------------------------------------------------------------

if minetest.global_exists("moretrees") then
	local function register_tree(treename)
		local trunk_name = 'moretrees:' .. treename .. '_trunk'
		local sappling_name = 'moretrees:' .. treename .. '_sapling'
		local leaves_name = 'moretrees:' .. treename .. '_leaves'

		tn(trunk_name, trunk_name, sappling_name)
		fn(leaves_name)
		gr({input=trunk_name, output=leaves_name .. ' 8'})
	end

	-- "ordinary" moretrees blocks
	for i in ipairs(moretrees.treelist) do
		local treename = moretrees.treelist[i][1]

		if treename ~= 'jungletree' then
			register_tree(treename)
		end
	end

	-- "weird" moretrees trunks
	tn('moretrees:date_palm_fruit_trunk', 'moretrees:date_palm_trunk', 'moretrees:date_palm_sapling')
	gr({input='moretrees:date_palm_fruit_trunk', output='moretrees:date_palm_leaves 8'})
	tn('moretrees:date_palm_ffruit_trunk', 'moretrees:date_palm_trunk', 'moretrees:date_palm_sapling')
	gr({input='moretrees:date_palm_ffruit_trunk', output='moretrees:date_palm_leaves 8'})
	tn('moretrees:date_palm_mfruit_trunk', 'moretrees:date_palm_trunk', 'moretrees:date_palm_sapling')
	gr({input='moretrees:date_palm_mfruit_trunk', output='moretrees:date_palm_leaves 8'})
	tn('moretrees:jungletree_trunk', 'default:jungletree', 'default:junglesapling')
	gr({input='moretrees:jungletree_trunk', output='default:jungleleaves 8'})
	tn('moretrees:palm_fruit_trunk', 'moretrees:palm_trunk', 'moretrees:palm_sapling')
	gr({input='moretrees:palm_fruit_trunk', output='moretrees:palm_leaves 8'})
	tn('moretrees:palm_fruit_trunk_gen', 'moretrees:palm_trunk', 'moretrees:palm_sapling')
	gr({input='moretrees:palm_fruit_trunk_gen', output='moretrees:palm_leaves 8'})
	tn('moretrees:rubber_tree_trunk_empty', 'moretrees:rubber_tree_trunk_empty', 'moretrees:rubber_tree_sapling')
	gr({input='moretrees:rubber_tree_trunk_empty', output='moretrees:rubber_tree_leaves 8'})

	-- moretrees fruit and leaves
	fn('moretrees:acorn')
	fn('moretrees:cedar_cone')
	fn('moretrees:coconut_3', 'moretrees:coconut')
	fn('moretrees:dates_f4', 'moretrees:date 16')
	fn('moretrees:fir_cone')
	fn('moretrees:fir_leaves_bright')
	fn('moretrees:jungletree_leaves_red')
	fn('moretrees:jungletree_leaves_yellow')
	fn('moretrees:spruce_cone')
end

