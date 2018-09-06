# Release Notes of the ModPack TechPack [techpack]



## V1.13.3 Beta (2018-09-06)

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
