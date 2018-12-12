local component = require("component")
local keyboard = require("keyboard")
local event = require("event")
local gpu = component.gpu

local debug = true

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
function eventHandlers.key_down(address, char, code, playerName)
  if (char == char_space) then
    running = false
  elseif (char == button_quit) then
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


-- run main loop --
local input = 0
running = true
print("starting")
i = 0
while running do
	-- Check inputs --
	local event, addr, p1, p2, p3 = event.pull(10) -- short timeout to not hang
	if event then
		handleEvent(event, addr, p1, p2, p3)
	end
end
