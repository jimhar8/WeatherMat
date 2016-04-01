local GPIO = require('periphery').GPIO

-- Open GPIO 17 with input direction
local gpio_in = GPIO(17, "in")
-- Open GPIO 18 with output direction
local gpio_out = GPIO(18, "out")

local value = gpio_in:read()
print(value)
gpio_out:write(false)

print("gpio_in properties")
print(string.format("\tpin: %d", gpio_in.pin))
print(string.format("\tfd: %d", gpio_in.fd))
print(string.format("\tdirection: %s", gpio_in.direction))
print(string.format("\tsupports interrupts: %s", gpio_in.direction))

gpio_in:close()
gpio_out:close()

