local component = require('component')
local computer = require("computer")
local keyboard = require("keyboard")
local event = require("event")
local term = require("term")

local core = component.proxy(component.list("nc_fission_reactor")())

local MAX_HEAT = core.getMaxHeatLevel()
local MAX_PWR = core.getMaxEnergyStored()

-- key bindings --
local button_quit = string.byte("q")
local button_up = string.byte("u")
local button_down = string.byte("d")

-- is program running or not
running = true

-- is reactor running
active = false

-- setup for event handling --
function unknownEvent()
  -- do nothing if the event wasn't relevant
end

-- table that holds all event handlers
-- in case no match can be found returns the dummy function unknownEvent
local eventHandlers = setmetatable({}, { __index = function() return unknownEvent end })

-- handle key presses --
function eventHandlers.key_up(address, char, code, playerName)
	if (char == button_quit) then
		running = false
	elseif (char == button_up) then
		print("up!")
		core.activate()
		active = true
	elseif (char == button_down) then
		print("down!")
		core.deactivate()
		active = false
	else
		-- nop on other keys --
	end
end

-- The main event handler as function to separate eventID from the remaining arguments
function handleEvent(eventID, ...)
  if (eventID) then -- can be nil if no event was pulled for some time
    eventHandlers[eventID](...) -- call the appropriate event handler with all remaining arguments
  end
end

-- shut down the reactor --
function shutdown()
	reactor.setActive(false)
	running = false
	term.clear()
end

-- beep a warning signal that power is low --
function warning_beep()
	computer.beep(1480, .8)
end

function printout (state)
	term.clear()
	print("Status:")
	print("Heat: ", state['heat']/MAX_HEAT*100, "% ", state['heat'], "/", MAX_HEAT)
	print("Power: ", state['pwr'], "/", MAX_PWR)
	print("Press q to quit")
end

comp_energy = 0
comp_energy_max = computer.maxEnergy()

while(running) do
		-- Check inputs --
	local event, addr, p1, p2, p3 = event.pull(1) -- short timeout to not hang
	if event then
		handleEvent(event, addr, p1, p2, p3)
	end
	
	-- If computer power low, fail system closed and shut down --
	comp_energy = computer.energy()/comp_energy_max * 100
	if(comp_energy < 25) then
		shutdown()
	elseif (comp_energy < 80) then
		warning_beep()
	end
	
	-- check state
	heat = core.getHeatLevel()
	pwr = core.getEnergyStored()
	rate = core.getEnergyChange()
	new_state = {heat=heat, pwr=pwr}
	
	-- activate if power needed and heat is manageable
	if heat/MAX_HEAT > 0.9 then
		active = false
	else
		if pwr/MAX_PWR > .95 then
			active = false
		else 
			active = true
		end
	end
	
	if active then
		core.activate()
	else
		core.deactivate()
	end
	

	printout(new_state)
	os.sleep(0.2)
end