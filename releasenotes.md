# Release Notes of the ModPack TechPack [techpack]



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

