# TechPack

TechPack, a Mining, Crafting, &amp; Farming Modpack for Minetest.

![TechPack](https://github.com/joe7575/techpack/blob/master/screenshot.png)

TechPack is a collection of following Mods:

* tubelib, a Mod for item exchange via lumber tubes and wireless message communication between nodes.
  ![README.md](https://github.com/joe7575/techpack/blob/master/tubelib/README.md)
* tubelib_addons1, a Tubelib extension with mining, farming, and crafting nodes
  ![README.md](https://github.com/joe7575/techpack/blob/master/tubelib_addons1/README.md)
* tubelib_addons2, a Tubelib extension with control nodes
  ![README.md](https://github.com/joe7575/techpack/blob/master/tubelib_addons2/README.md)
* gravelsieve, a Mod to sieve ores from gravel.
  ![README.md](https://github.com/joe7575/techpack/blob/master/gravelsieve/README.md)
* smartline, a Mod with small and smart sensors, actors and controllers.
  ![README.md](https://github.com/joe7575/techpack/blob/master/smartline/README.md)


TechPack is a collection of mods for an automated mining, crafting, and farming. It is no replacement for Pipeworks, Mesecons, Technic, and Co., but it is a lightweight and simple to use alternative for servers with the focus on building (not only playing around with technique stuff).
If a player uses the full potential of TechPack, he can work on his building projects while TechPack is producing most of the necessary materials in the meantime. 

A Tutorial to TechPack is available as ![Wiki](https://github.com/joe7575/techpack/wiki)

TechPack provides:
- lumber tubes to connect 2 nodes
- a Pusher node to pull/push items through tubes
- a Distributor node with 4 output channels to sort incoming items
- a Blackhole node which lets all items disappear
- Button/switches to send "switch on/off" messages
- Lamp nodes in different colors (can be switched on/off)
- a Quarry node to dig for stones and other ground nodes
- a Harvester node to chop wood, leaves and crops
- a Grinder node to grind cobble stone to gravel
- a Gravelsieve node to sieve ores from gravel
- an Autocrafter node for automated crafting of tools and items
- a Fermenter node to produce Bio Gas from leaves
- a Reformer node to produce Bio Fuel from Bio Gas (the Bio Fuel is needed by Harvester and Quarry nodes)
- a Funnel node to collect dropped items
- two Timer nodes for a daytime controlled sending of commands (on/off)
- two Sequencer nodes for a waiting time controlled sending of commands (on/off)
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
- a Signal Tower node showing machine states
- a Display node for text outputs of the Controller

### License
Copyright (C) 2017-2018 Joachim Stolberg  
Code: Licensed under the GNU LGPL version 2.1 or later. See LICENSE.txt  
Textures: CC BY-SA 3.0

### Dependencies 
default, doors.  
SmartLine Display optional: display_lib, font_lib  
SmartLine Controller optional: mail,  
Gravelsieve optional: moreores, hopper, pipeworks  
