# Release Notes for ModPack TechPack [techpack]



## V2.03.04 (2019-07-20)

### Additions

### Removals

### Changes

### Fixes
- Use Unified Dyes on_dig where needed (issue #35)


## V2.03.03 (2019-05-22)

### Additions

### Removals

### Changes

### Fixes
- Bug fixes from obl3pplifp (Blocky Survival) (issues #27, #28)
- Unstackable items vanish when using HighPerf pushers (issue #29)


## V2.03.02 (2019-05-09)

### Additions

### Removals

### Changes
- HighPerf Pusher support for autocrafter, grinder, and harvester 
  added (issue #22, #23)
- Both distributor behaviours changed (issue #26)

### Fixes
- Black Hole "items disappeared" counter bugfix (issue #24)
- HighPerf distributor behaviour without an active filtered channel 
  changed (issue #25)



## V2.03.01 (2019-05-03)

### Additions

### Removals

### Changes

### Fixes
- Warehouse nodes inventory handling bugfix



## V2.03 (2019-04-23)

### Additions
- Farming and Grinder recipes added (thanks to obl3pplifp)
- Support for Signs Bot chest and Box added

### Removals

### Changes

### Fixes
- Piston/WorldEdit/Replacer tool detection added. If node is replaced/removed/copied,
  it will switch to a "defect" dummy node.



## V2.02.06 (2019-03-23)

### Additions

### Removals

### Changes

### Fixes
- Warehouse boxes bugfix for the Blackhole bugfix



## V2.02.05 (2019-03-14)

### Additions

### Removals

### Changes

### Fixes
- Blackhole tube side bugfix



## V2.02.04 (2019-03-02)

### Additions

### Removals

### Changes

### Fixes
- Fermenter leaves bugfix (moretrees)



## V2.02.03 (2019-02-27)

### Additions

### Removals

### Changes

### Fixes
- industriallamp bugfix



## V2.02.02 (2019-02-16)

### Additions
- sl_controller: add battery status command

### Removals

### Changes

### Fixes
- forceload block bugfix



## V2.02.01 (2019-01-29)

### Additions

### Removals

### Changes
- Terminal related Controller commands changed

### Fixes
- Terminal output bugfix
- Controller event handling bugfix



## V2.02 (2019-01-28)

### Additions
- Tubelib_addons2 "Logic Not" added
- second (classical) SaferLua Terminal added

### Removals

### Changes
- Output reduction on Harvester (cycle time from 4 to 6 s), 
  Fermenter (from 2 to 3 input items needed per bio gas), 
  and Gravel Sieve (rarity from 1 to 1.5)

### Fixes
- removing the Gate block returns the original block


## V2.01 (2019-01-27)

### Additions
- SaferLua Terminal to be connected to the SaferLua Controller

### Removals

### Changes
- Server: formspec added to enter valid usernames for server access

### Fixes



## V2.00.07 (2019-01-27)

### Additions

### Removals

### Changes
- SmartLine Controller: Own node number to on/off command added to be able
  to cascade SmartLine Controllers

### Fixes



## V2.00.06 (2019-01-22)

### Additions

### Removals

### Changes

### Fixes
- SaferLua Collector: Formspec handling bugfix
- Quarry: Bugfix



## V2.00.05 (2019-01-21)

### Additions
- SmartLine Collector added

### Removals

### Changes
- SmartLine Repeater recipe
- SmartLine textures shrunken

### Fixes
- SaferLua-Controller: Event handling disabled when Controller is stopped



## V2.00.04 (2019-01-20)

### Additions
- SaferLua: range(from, to) added, standard string functions added

### Removals

### Changes

### Fixes
- SaferLua-Controller: Lua error messages bugfix
- SmartLine Server: data base was shared between several severs




## V2.00.03 (2019-01-19)

### Additions

### Removals

### Changes
- SaferLua-Controller: Lua error messages output improved
- SmartLine Display: row 0 can be used to set the infotext

### Fixes




## V2.00.02 (2019-01-15)

### Additions
- SaferLua: Init parameter to the function Store() added
- Warehouse Boxes: Command 'num_items' added
- SaferLua-Controller: Command 'num_items' added

### Removals

### Changes

### Fixes
- Distributors: Formspec bugfixes




## V2.00.01 (2019-01-13)

### Additions
- SaferLua-Controller: Support for Lua functions added
- Warehouse Boxes: Formspec tooltips added

### Removals

### Changes
- Grinder: Recipes for clay changed

### Fixes



## V2.00.00 (2019-01-12)

### Additions
- Almost all machines break after a certain amount of time (switch into the state 'defect') and have to be repaired.
- A Repair Kit is available to repair defect machines.
- A Forceload block (16x16x16) is added which keeps the corresponding area loaded and the machines operational as far as the player is logged in.
- Ladders, stairways, and bridges added for the machines (techpack_stairway)
- Industrial lamps added
- Warehouse Boxes in steel, copper, and gold for your warehouse/stock (techpack_warehouse) added

### Removals

### Changes
- TechPack now uses the external library 'tubelib2' (![GitHub](https://github.com/joe7575/tubelib2)), all tubes will be converted to be tubelib2 compatible
- TechPack depends now on the mod 'basic_materials' 
- The Quarry now uses LVM techniques to go down up to 100 meter
- Almost all machines have an 'on_node_load' function to repair timer routines after a server crash
- 3 settings parameter:
  - Maximum number of Forceload Blocks per player
  - Enable Basalt Stone (and disable ore generation via Cobblestone generator)
  - Machine aging value to calculate the lifetime of machines
- SmartLine Controller adapter to the new state 'defect'
- Gravel Sieve: Ore probability calculation changed (thanks to obl3pplifp)

### Fixes



## V1.16.7 (2018-11-30)

### Fixes
- Teleporter channel bug fixed

### Changes
- Fermenter: Improved input items processing (pull request from micu)



## V1.16.6 (2018-10-20)

### Fixes
- 'minetest.LIGHT_MAX' bugfix (Minetest 5.0.0)



## V1.16.5 (2018-10-14)

### Additions
- Cobblestone generation can be disabled via configuration

### Fixes
- Teleporter recursion bugfix
- tube bugfix



## V1.16.4 (2018-09-26)

### Additions
- Stopwatch function to SmartLine Controller added
- Display supports now left oriented text outputs via prefix '<'

### Fixes
- Owner bugfix for the SmartLine Controller



## V1.16.3 (2018-09-26)

### Changes
- Added further textures to the Gate Block



## V1.16.2 (2018-09-22)

### Changes
- Futher improvement of the "sneak" button usage



## V1.16.1 (2018-09-21)

### Additions
- Straight ahead tubes can be placed my means of the "sneak" button

### Fixes
- Minor tube placing bug fixed



## V1.16 (2018-09-20)

### Changes
- Switched from "Display mod pack" to an internal lcdlib, based
  on a former version of the Display mod pack. This was necessary
  due to extensive and ongoing changes on the Display mod pack API.

### Additions
- Added three kinds of sandstone to the grinder.



## V1.15.1 (2018-09-17)

### Fixes
- Button bug (detected in the video of Nathan) fixed



## V1.15 (2018-09-15)

### Additions
- Tubelib has a new helper function "get_inv_state()" used by the chests.
- The Lua Controller got a new command "$get_player_action()" to read the chest player state.
- SmartLine Controller got a new command to turn Distributor filter ports on/off.
- Chests send on/off commands for each player interaction to a node with a predefined number.
- Chests support the "player_action" command request.
- Chests support the "set_number" Programmer command to program a node number.

### Changes
- Chests now return the state "empty", loader" **and** "full".  
  "full" is returned, when no empty stack is available.

### Fixes
- Distributor and HighPerf Distributor item counter bugfixes.



## V1.14 Beta (2018-09-10)

### Additions
- The Tubelib chests now provide the states ("empty"/"loaded")
- The SmartLine Controller got the command "chest state request" for Tubelib chests
- Minetest fuel recipe for Bio Fuel added

### Changes
- The Distributor is now able to push up to 20 items per slot and phase (instead of 6).
- The Distributor now uses an unconfigured port for blocked/rejected items.
- The Tubelib Protected Chest got a new texture.
- The Harvester is now HighPerf Pusher compatible.


## V1.13.4 Beta (2018-09-08)

### Changes
- SmartLine Controller got some form/submenu updates



## V1.13.3 Beta (2018-09-06)

### Additions
- Sieved Gravel to Grinder recipes added

### Fixes
- Parameter 'side' bugfix (used e.g. for on_push_item(...)) 



## V1.13.2 Beta (2018-09-05)

### Changes
- Harvester continues now at that position, where it last switched to faulty.

### Fixes
- Recipe bug for SaferLua Controller fixed



## V1.13.1 Beta (2018-09-02)

### Changes
- Unloaded pushers now return "blocked", if the status is requested.
  Before, it returned the last stored state.

### Fixes
- Bug in the "HighPerf Pushing Chest" fixed. For the case the node pushes items
  in its own chest, the items went lost.



## V1.13 Beta (2018-08-28)

### Additions
- A Liquid Sampler node is added. It is able to take all kind or renewable liquids (registered via bucket.register_liquid)
  Currently only useful for recipes where a water-bucket is needed.
- Smartline has a new IF-THIS-THEN-THAT Controller V2 which should be much simpler to use. 
  It will replace the current one (V1).  
  Currently both are active, but if you dig a controller V1 it will be converted to a controller V2.
- The new controller needs batteries. Thus, Smartline has now its own battery node. The sl_controller.battery will not be
  needed any more.

### Removals
- recipe for sl_controller/batteries removed.
- Recipe for Smartline controller V1 removed.

### Changes
- Quarry can no go direct from FAULT into RUNNING without reset the digging position

### Fixes
- bug in open/close door command for Minetest v0.4.17+ fixed




-------------------------------------------------------------
## Vx.xx.x (2018-mm-dd)

### Additions

### Removals

### Changes

### Fixes
