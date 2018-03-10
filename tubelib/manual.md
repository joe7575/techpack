# Tubelib Library

## Hints for Admins and Players

Tubelib is little useful for itself, it makes only sense with extensions such as:  
- ![tubelib_addons1](https://github.com/joe7575/tubelib_addons1) with farming nodes like Harvester, Quarry, Grinder, Autocrafter, Fermenter and Reformer.
- ![tubelib_addons2](https://github.com/joe7575/tubelib_addons2) with control task nodes like Timer, Sequencer, Repeater, Gate, Door, Access Lock and Color Lamp.

However Tubelib provides the following basic nodes:

### Tubes
Tubes allow the item exchange between two nodes. Tube forks are not possible. You have to use chests 
or other inventory nodes as hubs to build more complex structures.
Tubes for itself are passive. For item exchange you have to use pulling/pushing nodes in addition.
The maximum tube length is limited to 100 nodes.

### Pusher
The Pusher is able to pull one item out of one inventory node and pushing it into another inventory node directly or by means of tubes.
It the source node is empty or the destination node full, the Pusher goes into STANDBY state for some seconds.

### Distributor
The Distributor works as filter and pusher. It allows to divide and distribute incoming items into 4 tube channels.
The channels can be switched on/off and individually configured with up to 6 items. The filter passes the configured
items and restrains all others. To increase the throughput, one item can be added several times to a filter.
An unconfigured but activated filter allows to pass up to 6 remaining items.

### Button/Switch
The Button/Switch is a simple communication node for the Tubelib wireless communication.
This node can be configured as button and switch. For the button configuration different switching
times from 2 to 16 seconds are possible. The Button/Switch node has to be configured with the destination
number of the receiving node (e.g. Lamp). This node allows to address several receivers by means or their numbers.
All numbers of the receiving nodes have to be added a configuration time.

### Lamp
The Lamp is a receiving node, showing its destination/communication number via "infotext".
The Lamp can be switched on/off by means of the right mouse button (use function) or by means of messages commands
from a Button/Switch or any other command sending node.


