--[[
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This is a direct copy of what's in the Adafruit Python GPIO library:
#  https://raw.githubusercontent.com/adafruit/Adafruit_Python_GPIO/master/Adafruit_GPIO/Platform.py
# TODO: Add dependency on Adafruit Python GPIO and use its platform detect
# functions.

--]]

local platform = {}

-- Platform identification constants.
platform.UNKNOWN          = 0
platform.RASPBERRY_PI     = 1

function platform.platform_detect()
	return platform.RASPBERRY_PI
end



function platform.pi_version()
    --[["""Detect the version of the Raspberry Pi.  Returns either 1, 2 or
    None depending on if it's a Raspberry Pi 1 (model A, B, A+, B+),
    Raspberry Pi 2 (model B+), or not a Raspberry Pi.
    """]]--
    -- Check /proc/cpuinfo for the Hardware field value.
    -- 2708 is pi 1
    -- 2709 is pi 2
    -- Anything else is not a pi.
	
	local hardware = ""
	
	local f = io.open('/proc/cpuinfo', 'r')
	local cpuinfo = f:read("*all")
	f:close()
	
		
    -- Match a line like 'Hardware   : BCM2709'
    hardware = cpuinfo:match('Hardware%s+[:]%s+(%w+)')
	
				  
    if not hardware then
        --# Couldn't find the hardware, assume it isn't a pi.
        return nil
	end	
		
    if hardware == 'BCM2708' then 
        --# Pi 1
        return 1
    elseif hardware == 'BCM2709' then
        --# Pi 2
        return 2
    else
        --# Something else, not a pi.
        return nil
	end

end

return platform
