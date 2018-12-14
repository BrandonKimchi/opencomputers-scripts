local component = require("component")
local computer = require("computer")
local keyboard = require("keyboard")
local event = require("event")
local term = require("term")
local gpu = component.gpu

local reactor = component.br_reactor
local turbine = component.br_turbine

-- config parameters --
local goal_turbine_speed = 1800
local turbine_activation_threshold = 1600
local meltdown_threshold = 1900



-- key bindings --
local button_quit = string.byte("q")
local button_up = string.byte("u")
local button_down = string.byte("j")

local debug = false

-- Assuming screen is 2x1 tier 2 monitors for now --
gpu.setResolution(80, 25)

function debug(str)
	if debug then
		print(str)
	end
end

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
  if (eventID) then -- can be nil if no event was pulled for some time
    eventHandlers[eventID](...) -- call the appropriate event handler with all remaining arguments
  end
end


-- shut down the reactor --
function shutdown()
	reactor.setActive(false)
	running = false
end

-- beep a warning signal that power is low --
function warning_beep()
	computer.beep(1480, .8)
end


-- PID update calculation to keep turbine RPMs in the strike zone --
function PID(rpm)
	return 0
end


-- run main loop --
local input = 0
running = true
print("starting")

core_temp = 0
case_tmep = 0
energy_stored = 0
energy_stored_max = 0

turb_speed = 0
turb_intake_rate = 0
turb_inductor_on = turbine.getInductorEngaged()

control_rod_level = 0 -- we'll just move them all as one

comp_energy = 0
comp_energy_max = computer.maxEnergy()



while running do
	-- Check inputs --
	local event, addr, p1, p2, p3 = event.pull(1) -- short timeout to not hang
	if event then
		handleEvent(event, addr, p1, p2, p3)
	end

	-- Read current reactor state --
	core_temp = reactor.getFuelTemperature()
	case_temp = reactor.getCasingTemperature()
	control_rod_level = reactor.getControlRodLevel(0)

	energy_stored = turbine.getEnergyStored()
	turb_speed = turbine.getRotorSpeed()
	energy_gen = turbine.getEnergyProducedLastTick()

	turb_inductor_on = turbine.getInductorEngaged()



	-- If computer power low, fail system closed and shut down --
	comp_energy = computer.energy()/comp_energy_max * 100
	if(comp_energy < 25) then
		shutdown()
	elseif (comp_energy < 80) then
		warning_beep()
	end

	-- If our energy is full, turn off to save fuel --
	if (energy_stored > 900000) then
		reactor.setActive(false)
	end

	-- Startup routine --
	if (energy_stored < 100000) then
		reactor.setActive(true)
		turbine.setInductorEngaged(false)
	end

	if(turb_speed > turbine_activation_threshold) then
		turbine.setInductorEngaged(true)
	end

	control_rod_delta = PID(turb_speed)

	-- avoid meltdown --
	if(case_temp > meltdown_threshold or core_temp > meltdown_threshold) then
		shutdown()
	end

	-- Print our current state --
	term.clear()
	print("State:")
	if turb_inductor_on then
		print("Turbine: ", "on")
	else
		print("Turbine: ", "off")
	end
	print("Core temp: ", core_temp)
	print("Casing temp: ", case_temp)

	print("Rotor speed: ", turb_speed .. " rpm")
	print("Energy generated: ", energy_gen)
	print("Energy stored: ", energy_stored .. "/1000000")
	print("Computer Power: ", comp_energy .. "%")
end
