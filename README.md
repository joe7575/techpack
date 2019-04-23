# TechPack V2.02

TechPack, a Mining, Crafting, &amp; Farming Modpack for Minetest.

![TechPack](https://github.com/joe7575/techpack/blob/master/screenshot.png)

**After update to v2, don't forget to activate the new mods "techpack_stairway" and "techpack_warehouse" as part of the mod pack.**


TechPack is a collection of following Mods:

* tubelib, a Mod for item exchange via lumber tubes and wireless message communication between nodes.
* tubelib_addons1, a Tubelib extension with mining, farming, and crafting nodes
* tubelib_addons2, a Tubelib extension with control nodes
* tubelib_addons3, a Tubelib extension with high performance nodes
* techpack_stairway, Ladders, stairways, and bridges for your machines
* techpack_warehouse, Warehouse Boxes in steel, copper, and gold
* gravelsieve, a Mod to sieve ores from gravel.
* smartline, a Mod with small and smart sensors, actors and controllers.
* safer_lua, a subset of the language Lua for safe and secure Lua sandboxes
* SaferLua Controller - a controller to be programmed in LUA
* lcdlib - a display lib used by smartline

**A TechPack Tutorial is available as ![Wiki](https://github.com/joe7575/techpack/wiki)**

**Machine data is stored in memory and not in the nodes itself. Therefore, never move or copy machines or tubes by means of Worldedit.**
**The moved/copied nodes will not have valid node numbers, which could lead to a server crash.**

TechPack provides:
- lumber tubes to connect 2 nodes
- a Pusher node to pull/push items through tubes
- a Distributor node with 4 output channels to sort incoming items
- a Blackhole node which lets all items disappear
- Button/switches to send "switch on/off" messages
- a Forceload block to keep your machines operational
- Several lamp nodes in different colors (can be switched on/off)
- a Quarry node to dig for stones and other ground nodes
- a Harvester node to chop wood, leaves, flowers and crops
- a Grinder node to grind all kinds of cobblestone to gravel, gravel to sand, and sand to clay
- a Gravelsieve node to sieve ores from gravel
- an Autocrafter node for automated crafting of tools and items
- a Fermenter node to produce Bio Gas from leaves
- a Reformer node to produce Bio Fuel from Bio Gas (the Bio Fuel is needed by Harvester and Quarry nodes)
- a Funnel node to collect dropped items
- two Timer nodes for a daytime controlled sending of commands (on/off)
- two Sequencer nodes for a waiting time controlled sending of commands (on/off)
- an item Detector node sending commands (on/off)
- a Repeater node to distribute received commands to connected nodes
- a Logic Not node to invert on/off commands
- Gate/Door nodes in different textures to be controlled via on/off commands
- an Access Lock node with number key field 
- a Mesecon Converter node to translate tubelib commands in mesecon commands and vice versa
- a Programmer tool to simply collect node numbers
- a Player Detector node
- a Controller node with "IF this then that" rules, which allows: 
  - reading node states
  - receiving commands from other nodes
  - sending commands and alarms
  - sending mails or chat messages
  - output on a display
- a Controller to be programmed in Lua
- a Terminal to be connected to the Lua Controller
- a Signal Tower node showing machine states
- a Display node for text outputs of the Controller
- Metal ladders, stairways, and bridges
- Warehouse Boxes in steel, copper, and gold


TechPack supports the following mods:
- Farming Redo (Harvester, Fermenter)
- Ethereal (Harvester, Quarry, Fermenter)
- Pipeworks (Gravel Sieve)
- Hopper (Gravel Sieve)
- Mesecon (Mesecon Converter)


### Configuration
The following can be changed in the minetest menu (Settings -> Advanced Settings -> Mods -> tubelib) or directly in 'minetest.conf'
- Maximum number of Forceload Blocks per player
- Enable Basalt Stone (and disable ore generation via Cobblestone generator)
- Machine aging value to calculate the lifetime of machines

Example for 'minetest.conf':
```LUA
tubelib_basalt_stone_enabled = false
tubelib_max_num_forceload_blocks = 12
tubelib_machine_aging_value = 200
```

Example for a v1 compatible 'minetest.conf':
```LUA
tubelib_basalt_stone_enabled = false
tubelib_max_num_forceload_blocks = 0
tubelib_machine_aging_value = 999999
```


#### Maximum number of Forceload Blocks per player
Default value is 12.  
I higher number allows to build larger farms and machines which keep loaded, but increases the server load, too.
But the areas are only loaded when the player is online.
To be able to use e.g. 12 forceloaded blocks per player, the pararamter 'max_forceloaded_blocks' in 'minetest.conf' has to be ajusted. 

#### Enable Basalt Stone (and disable ore generation via Cobblestone generator)
The lava/water Cobblestone generator allows to produce infinite Cobblestone. By means of Quarry, 
Grinder, and Gravel Sieve it allows to infinite generate ores.  
This can be disabled by means of the setting parameter. If enabled, the Cobblestone 
generator generates Basalt instead, which only can be used for building purposes.

#### Machine aging value to calculate the lifetime of machines
Default value is 200.  
This aging value is used to calculate the lifetime of machines before they go defect.
The value 200 (default) results in a lifetime for standard machines of about 2000 - 8000 item processing cycles (~2-4 hours).


### License
Copyright (C) 2017-2019 Joachim Stolberg  
Code: Licensed under the GNU LGPL version 2.1 or later. See LICENSE.txt  
Textures: CC BY-SA 3.0


### Dependencies 
default, doors, intllib, basic_materials  
tubelib2 (![GitHub](https://github.com/joe7575/tubelib2))  
Tubelib Color Lamps optional: unifieddyes  
SmartLine Controller optional: mail  
Gravelsieve optional: moreores, hopper, pipeworks  
tubelib_addons1 optional: unified_inventory

### History 
- 2018-03-18  V1.00  * Tubelib, tubelib_addons1, tubelib_addons2, smartline, and gravelsieve combined to one modpack.
- 2018-03-24  V1.01  * Support for Ethereal added
- 2018-03-27  V1.02  * Timer improvements for unloaded areas
- 2018-03-29  V1.03  * Area protected chest added to tubelib_addons1
- 2018-03-31  V1.04  * Maintenance, minor issues, Unifieddyes support for Color Lamp, Street Lamp added
- 2018-04-27  V1.05  * Ceiling lamp added, further improvements
- 2018-06-09  V1.06  * Recipes with API to grinder added
- 2018-06-17  V1.07  * Tube placement completely reworked
- 2018-06-22  V1.08  * Lua Controller and SaferLua added
- 2018-07-22  V1.09  * Item counters for Pusher/Distributor and tubelib commands for Autocrafter added
- 2018-08-08  V1.10  * tubelib_addon3 with high performance nodes added
- 2018-08-13  V1.11  * Detector node added
- 2018-08-14  V1.12  * Teleporter node added
- 2018-08-28  V1.13  * Smartline Controller completely revised. Liquid Sampler added
- 2018-09-10  V1.14  * Distributor performance improved, chest commands added
- 2018-09-15  V1.15  * Smartline Controller command added, chest commands improved
- 2018-09-20  V1.16  * Switched from "Display mod pack" to lcdlib
- 2018-12-23  V2.xx  * on the way to v2
- 2018-12-29  V2.00  * beta
- 2019-01-12  V2.00  * release
- 2019-01-27  V2.01  * SaferLua Controller Terminal added
- 2019-01-28  V2.02  * Logic Not added, output reduction on Harvester, Fermenter, and Gravel Sieve
- 2019-04-23  V2.03  * Piston/WorldEdit/replacer detection added, farming and grinder recipes added


## New in v2 (from players point of view)
- Almost all machines break after a certain amount of time (switch into the state 'defect') and have to be repaired.
- A Repair Kit is available to repair defect machines.
- A Forceload block (16x16x16) is added which keeps the corresponding area loaded and the machines operational as far as the player is logged in.
- The Quarry now uses LVM techniques to go down up to 100 meter
- Ladders, stairways, and bridges added for the machines (techpack_stairway)
- Industrial lamps
- Warehouse Boxes in steel, copper, and gold for your warehouse/stock (techpack_warehouse)


## New in v2 (from admins point of view)
- settingtypes introduced with the following settings: tubelib_max_num_forceload_blocks, tubelib_basalt_stone_enabled, tubelib_machine_aging_value
- the new mods 'techpack_stairway' and 'techpack_warehouse' have to be enabled
- TechPack depends now on the mod 'basic_materials' and 'tubelib2' (![GitHub](https://github.com/joe7575/tubelib2))

See ![releasenotes.txt](https://github.com/joe7575/techpack/blob/master/releasenotes.md) for further information
