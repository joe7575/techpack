# SmartLine Controller API


The SmartLine Controller provides the following API to register additional condition and action commands from other mods:

* smartline.register_condition(name, condition definition)
* smartline.register_action(name, action definition)


Each registered condition and action has the function `on_execute`  which is called for each rule (every second).
* The condition function has to return true or false, depending if the condition is true or not.
* The action function has to execute the defined action.

In addition each registered condition and action has the function `button_label`, which determines the button label
for the Controller main formspec. Please note that the maximum number of visible characters for the button label is
something about 15.

See `commands.lua` as reference. All predefined SmartLine Controller commands are registered via `commands.lua`.

## Prototypes

```LUA
smartline.register_condition(name, {
	title = "my condition",
	formspec = {},
	on_execute = function(data, environ) 
	-- data:    table with the formspec data 
	-- environ: not relevant here
	end,
	button_label = function(data) 
	   return "button label"
	end,
})
```


```LUA
smartline.register_action(name, {
	title = "my action",
	formspec = {},
	on_execute = function(data, environ, inputs) 
	-- data:    table with the formspec data 
	-- environ: not relevant here
	-- inputs:  table with the input values
	end,
	button_label = function(data) 
	   return "button label"
	end,
})
```

The 'name' parameter should be unique. External mods should use the mod name as prefix, like "mymod_mycond".
The 'title' is used in the main menu for the condition and action selection dialog.
The 'formspec' table defines the condition/action related form for additional user parameters.
It supports the following subset of the minetest formspec elements:

  - textlist
  - field
  - label

Please note that size and position is automatically determined.
All other attributes are according to the original formspec.
Example:

```LUA
formspec = {
	{
		type = "field",                          -- formspec element
		name = "number",                         -- reference key for the table 'data'
		label = "input from node with number",   -- label shown above of the element
		default = "",                            -- default value
	},
	{
		type = "textlist",                       -- formspec element
		name = "value",                          -- reference key for the table 'data'
		label = "is",                            -- label shown above of the element
		choices = "on,off",                      -- list elements
		default = 1,                             -- first list element as default value
	},
	{
		type = "label",
		name = "lbl",                            -- not really used, but internally needed
		label = "Hint: Connect the input nodes with the controller", 
	},
}
```

The table 'data' includes the condition/action related 'formspec' data. 
For the above 'formspec' example, it is:

```LUA
    data = {
        number = <string>,       -- the entered value of the "field",
        value = <number>,        -- the number of the selected element of the "textlist"
        value_text = <string>,   -- in addition the text of the selected element of the "textlist"
    }
```

