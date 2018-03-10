# Tubelib Extension with Control Blocks \[tubelib_addons2\]

This extension provides Timer, Sequencer, Repeater, Gate, Door, Access Lock, Mesecons Converter and Color Lamp nodes, all with tubelib communication support.


## Timer
The Timer node allows to send on/off commands to other nodes, e.g. to switch on/off lights at night.
Up to 6 independent rules with daytime, destination node numbers, and on/off command can be programmed. 


## Sequencer
The Sequencer node allows to define sequences of on/off commands with time gaps in between. 
For this purpose, a sequence of up to 8 steps can be programmed, each with
destination node numbers, on/off command, and time gap to the next step in seconds.
The Sequencer can run endless or only once and can be switches on/off by other nodes.


## Repeater
The Repeater is a concentrator node to distribute received commands to all connected nodes.
The list of destination node numbers can be programmed by means of the Programmer.


## Gate/Door
Doors, gates and locks can be build by means of Tubelib Gate and Door nodes.
With the command 'on' the node disappears, with 'off' it appears again.
The texture of the node can be configured after placement with the right mouse button.


## Access Lock
The Access Lock node is a combination lock to open/close gates and doors (active for 4 seconds).
The list of destination node numbers can be programmed by means of the Programmer.


## Color Lamp
A set of colored lamps with Tubelib support.
The color of the lamp can be configured after placement with the right mouse button.


## Mesecons Converter
The Mesecons Converter node allows the connection of Tubelib nodes with Mesecon wires and vice versa.
The list of destination node numbers can be programmed by means of the Programmer.


## Programmer
The Programmer is a tool to collect node numbers (right mouse button) from receiving nodes to program 
sending nodes (left mouse button).


## Dependencies
tubelib, default  

