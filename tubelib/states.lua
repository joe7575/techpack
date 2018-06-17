--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	states.lua:

	A state model for tubelib nodes.

]]--

--
-- Inventory Button States
--

tubelib.STOPPED = 1		-- not operational
tubelib.RUNNING = 2		-- in normal operation
tubelib.STANDBY = 3		-- nothing to do or blocked anyhow
tubelib.FAULT   = 4		-- any fault state, which has to be fixed by the player

tubelib.StatesImg = {
	"tubelib_inv_button_off.png", 
	"tubelib_inv_button_on.png", 
	"tubelib_inv_button_standby.png", 
	"tubelib_inv_button_error.png"
}

-- Return state button image for the node inventory
function tubelib.state_button(state)
	if state and state < 5 and state > 0 then
		return tubelib.StatesImg[state]
	end
	return tubelib.StatesImg[tubelib.FAULT]
end

-- State string based on button states
tubelib.states = {"stopped", "running", "standby", "fault"}
	

--
-- 'running' variable States
--

tubelib.STATE_RUNNING = 1		-- in normal operation
tubelib.STATE_STOPPED = 0		-- not operational
tubelib.STATE_STANDBY = -1		-- nothing to do
tubelib.STATE_BLOCKED = -2		-- pushing node is blocked due to a full inventory
tubelib.STATE_FAULT   = -3		-- any fault state, which has to be fixed by the player

-- Return machine state based on the running counter
function tubelib.state(running)
	if running > 0 then
		return tubelib.RUNNING
	elseif running == 0 then
		return tubelib.STOPPED
	elseif running == -1 then
		return tubelib.STANDBY
	elseif running == -2 then
		return tubelib.BLOCKED
	else
		return tubelib.FAULT
	end
end

-- Return state string based on the running counter
function tubelib.statestring(running)
	if running > 0 then
		return "running"
	elseif running == 0 then
		return "stopped"
	elseif running == -1 then
		return "standby"
	elseif running == -2 then
		return "blocked"
	else
		return "fault"
	end
end