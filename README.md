# TechPack V1.16

TechPack, a Mining, Crafting, &amp; Farming Modpack for Minetest.

![TechPack](https://github.com/joe7575/techpack/blob/master/screenshot.png)

**After update to v1.16, don't forget to activate the new mod "lcdlib" as part of the mod pack.**


TechPack is a collection of following Mods:

* tubelib, a Mod for item exchange via lumber tubes and wireless message communication between nodes.
* tubelib_addons1, a Tubelib extension with mining, farming, and crafting nodes
* tubelib_addons2, a Tubelib extension with control nodes
* tubelib_addons3, a Tubelib extension with high performance nodes
* gravelsieve, a Mod to sieve ores from gravel.
* smartline, a Mod with small and smart sensors, actors and controllers.
* safer_lua, a subset of the language Lua for safe and secure Lua sandboxes
* SaferLua Controller - a controller to be programmed in LUA
* lcdlib - a display lib used by smartline


**A TechPack Tutorial is available as ![Wiki](https://github.com/joe7575/techpack/wiki)**

TechPack is a collection of mods for an automated mining, crafting, and farming. It is no replacement for Pipeworks, Mesecons, Technic, and Co., but it is a lightweight and simple to use alternative for servers with the focus on building (not only playing around with technique stuff).
If a player uses the full potential of TechPack, he can work on his building projects while TechPack is producing most of the necessary materials in the meantime. 



TechPack provides:
- lumber tubes to connect 2 nodes
- a Pusher node to pull/push items through tubes
- a Distributor node with 4 output channels to sort incoming items
- a Blackhole node which lets all items disappear
- Button/switches to send "switch on/off" messages
- Several lamp nodes in different colors (can be switched on/off)
- a Quarry node to dig for stones and other ground nodes
- a Harvester node to chop wood, leaves and crops
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
- a Signal Tower node showing machine states
- a Display node for text outputs of the Controller

TechPack supports the following mods:
- Farming Redo (Harvester, Fermenter)
- Ethereal (Harvester, Quarry, Fermenter)
- Pipeworks (Gravel Sieve)
- Hopper (Gravel Sieve)
- Mesecon (Mesecon Converter)


### Configuration
- Enable cobblestone generation (true/false)  
  If set to false, the lava/water cobblestone generator produces Basalt instead, 
  which can't be used by TechPack.


### License
Copyright (C) 2017-2018 Joachim Stolberg  
Code: Licensed under the GNU LGPL version 2.1 or later. See LICENSE.txt  
Textures: CC BY-SA 3.0

### Dependencies 
default, doors.  
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

See ![releasenotes.txt](https://github.com/joe7575/techpack/blob/master/releasenotes.md) for further information