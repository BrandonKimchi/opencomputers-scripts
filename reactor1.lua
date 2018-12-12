local component = require("component")
local computer = require("computer")
local keyboard = require("keyboard")
local event = require("event")
local gpu = component.gpu

local reactor = component.br_reactor
local turbine = component.br_turbine

local debug = false

-- Assuming screen is 2x1 tier 2 monitors for now --
gpu.setResolution(80, 25)

function debug(str)
	if debug then
		print(str)
	end
end

-- key bindings --
local button_quit = string.byte("q")
local button_up = string.byte("u")
local button_down = string.byte("j")

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
	elseif (char == button_down) then
		print("down!")
	else
		-- nop on other keys --
	end
end

-- The main event handler as function to separate eventID from the remaining arguments
function handleEvent(eventID, ...)
	debug("handling event!")
  if (eventID) then -- can be nil if no event was pulled for some time
    eventHandlers[eventID](...) -- call the appropriate event handler with all remaining arguments
  end
end


-- shut down the reactor --
function shutdown()

end

-- beep a warning signal that power is low --
function warning_beep()

end


-- run main loop --
local input = 0
running = true
print("starting")

core_temp = 0
case_tmep = 0
energy_stored = 0

comp_energy = 0
comp_energy_max = computer.maxEnergy()

while running do
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

	-- Read current reactor state --
	core_temp = reactor.getFuelTemperature()
	case_temp = reactor.getCasingTemperature()

	-- Print our current state --
	print("State:")
	print("Core temp: ", core_temp)
	print("Casing temp: ", case_temp)

	print("Computer Power: ", comp_energy)
end
