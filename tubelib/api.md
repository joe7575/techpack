# Tubelib Programmers Interface


Tubelib supports:
- StackItem exchange via tubes and
- wireless data communication between nodes.

  

## 1. StackItem Exchange 

Tubes represent connections between two nodes, so that it is irrelevant
if the receiving node is nearby, or far away connected via tubes.
The length of the tube is limited to 100 nodes.

For StackItem exchange we have to distinguish the following roles:
- client: An active node calling push/pull functions
- server: A passive node typically with inventory, which will be called

Client and server API use the following special parameters:

- `side` the contact side where the items shall be pulled out or pushed in.
  This is one of B(ack), R(ight), F(ront), L(eft), D(own), U(p) according to the
  following diagram (view onto the placed node). It can be used to separate
  incoming items for different inventories.

```
                        Up    Back
                        |    /
                        |   /
                     +--|-----+
                    /   o    /|
                   +--------+ |
          Left ----|        |o---- Right
                   |    o   | |
                   |   /    | +
                   |  /     |/
                   +-/------+
                    /   |
                 Front  |
                        |
                      Down
```

- `player_name`: Normally the name of the player, who placed the pushing node.
  But this could also be used to identify the player interacting with the
  pushing node.

The use of both parameters on server side is not required. See chap. 4 for an example
of an inventory node.

  
  
## 2. Data communication

For the data communication an addressing method based on node numbers is used. 
Each registered node gets a unique node number with 4 figures (or more if needed).
The numbers are stored in a storage list. That means, a new node, placed on 
the same position gets the same node number as the previously placed node on that 
position.

The communication supports two services:
- `send_message`: Send a message to one or more nodes without response
- `send_request`: Send a messages to exactly one node and return the response

It is up to the programmer, which messages shall be supported.
But if a node can be switched on/off or started/stopped, use "on" and "off" as commands
for both cases.

  
  
## 3. API Functions


### Register, Add, Remove Nodes

Before a node can take part on the item exchange via tubes or data communication,
it has to be registered once.

```LUA
    tubelib.register_node(name, add_names, node_definition)
```
Call this function only at load time!
Parameters:
- name: The node name like "tubelib:pusher"
- add_names: A table with additional node names if needed, e.g.: "tubelib:pusher_active"
- node_definition: A table with the server callback functions according to:

```LUA
    {
        on_pull_item = func(pos, side, player_name),
        -- Pull an item from the node inventory.
        -- The function shall return an item stack with one element
        -- like ItemStack("default:cobble") or nil.
        -- Param side: The node contact side, where the item shall be pulled out.
        -- Param player_name: Can be used to check access rights.

        on_push_item = func(pos, side, item, player_name),
        -- Push the given item into the node inventory.
        -- Param side: The node contact side, where the item shall be pushed in.
        -- Param player_name: Can be used to check access rights.
        -- The function shall return true if successful, or false if not.

        on_unpull_item = func(pos, side, item, player_name),
        -- Undo the previous pull and place the given item back into the inventory.
        -- Param side: The node contact side, where the item shall be unpulled.
        -- Param player_name: Can be used to check access rights.
        -- The function shall return true if successful, or false if not.

        on_recv_message = func(pos, topic, payload),
        -- Execute the requested message
        -- Param topic: A topic string like "on"
        -- Param payload: Additional data for more come complex commands, 
        --                payload can be a number, string, or table.
        -- The function shall return true/false for commands like on/off 
        -- or return the requested data for commands like a "state" request.
    }
```

**Each node has to call:**

```LUA
    tubelib.add_node(pos, name)
```
`add_node` shall be called when the node is placed. 
The function is used to register the nodes position for the communication node 
number and to update the tube surrounding.
`pos` the node position, `name` is the node name.

  

```LUA
    tubelib.remove_node(pos)
```
'remove_node' shall be called then the node is dig.
The function is used to remove the node number from the internal list.

  

### Item Exchange via Tubes

For item exchange as a pushing/pulling node the following functions exist:

```LUA
    tubelib.pull_items(pos, side, player_name)
```
Pull one item from the given position specified by `pos` and `side`.
Parameters:
- `pos` is the own node position
- `side` is the contact side, where the item shall be pulled in 
- `player_name` can be used to check access rights.
- The function returns an item stack with one element like ItemStack("default:cobble") or nil.
  

```LUA
    tubelib.push_items(pos, side, items, player_name)
```
Push one item to the given position specified by `pos` and `side`.
Parameters:
- `pos` is the own node position
- `side` is the contact side, where the item shall be pushed out 
- `item` is an item stack with one element like ItemStack("default:cobble")
- `player_name` can be used to check access rights.
The function returns true if successful, or false if not.

  

```LUA
    tubelib.unpull_items(pos, side, items, player_name)`
```
Undo the previous pull and place the item back into the inventory.
Parameters:
- `pos` is the own node position
- `side` id the node contact side, where the item shall be unpulled
- `player_name` can be used to check access rights.
The function returns true if successful, or false if not.

  
  
### Wireless Data Communication

For data communication the following functions exist:

```LUA
    tubelib.send_message(numbers, placer_name, clicker_name, topic, payload)
```
Send a message to all nodes referenced by `numbers`, a string with
one or more destination node numbers separated by blanks. 
The message is based on a topic string (e.g. "start") and
a topic related payload.
The placer and clicker names are needed to check the protection rights. 
`placer_name` is the name of the player, who places the node.
`clicker_name` is the name of the player, who uses the node.
`placer_name` of sending and receiving nodes have to be the same.
If every player should be able to send a message, use nil for `clicker_name`.
Because several nodes could be addressed, the function don't return any response.


```LUA
    tubelib.send_request(number, topic, payload)
```
In contrast to `send_message` this functions send a message to exactly one node 
referenced by `number` and returns the node response. 
The message is based on the topic string (e.g. "state") and
topic related payload.
  

## 4. Code Snippets

### Register Node (from 'legacy_nodes.lua')

```LUA
    tubelib.register_node("default:chest", {"default:chest_open"}, {
    	on_pull_item = function(pos, side, player_name)
    		local meta = minetest.get_meta(pos)
    		return tubelib.get_item(meta, "main")
    	end,
    	on_push_item = function(pos, side, item, player_name)
    		local meta = minetest.get_meta(pos)
    		return tubelib.put_item(meta, "main", item)
    	end,
    	on_unpull_item = function(pos, side, item, player_name)
    		local meta = minetest.get_meta(pos)
    		return tubelib.put_item(meta, "main", item)
    	end,
    })	
```


### Add/remove node (from 'lamp.lua')

```LUA
	after_place_node = function(pos, placer)
		local number = tubelib.add_node(pos, "tubelib:lamp")
		...
	end,

	after_dig_node = function(pos)
		tubelib.remove_node(pos)
	end,
```

### Item exchange via tubes (from 'pusher.lua')

```LUA
	local items = tubelib.pull_items(pos, "L", player_name)
	if items ~= nil then
		if tubelib.push_items(pos, "R", items, player_name) == false then
			tubelib.unpull_items(pos, "L", items, player_name)
		end
	end
```

### Message communication (from 'button.lua')

```LUA
	local number = meta:get_string("number")
	local placer_name = meta:get_string("placer_name")
	tubelib.send_message(number, placer_name, nil, "stop", nil)
```

### 5. Example Code

Tubelib includes the following example nodes which can be used for study
and as templates for own projects:

- pusher.lua:    a simple client pushing/pulling items
- blackhole.lua: a simple server client, makes all items disappear
- button.lua:    a simple communication node, only sending messages
- lamp.lua:      a simple communication node, only receiving messages


## 6. Further information

The complete functionality is implemented in the file 
![command.lua](https://github.com/joe7575/techpack/blob/master/tubelib/command.lua). 
This file has further helper functions and is recommended for deeper study.

## 7. History

2017-10-02  First draft  
2017-10-29  Commands start/stop replaced by on/off  
2018-03-31  Corrections for 'send_request' and 'add_node'
