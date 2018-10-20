# Release Notes of the ModPack TechPack [techpack]



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
