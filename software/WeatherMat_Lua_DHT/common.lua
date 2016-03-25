--[[ 

Permission is hereby granted, free of charge, to any person obtaining a copy
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

--]]

local common = {}

local platform = require "platform"
--local Raspberry_Pi_module = require "Raspberry_Pi"
local Raspberry_Pi_2 = require "Raspberry_Pi_2"


-- Define error constants.
DHT_SUCCESS        =  0
DHT_ERROR_TIMEOUT  = -1
DHT_ERROR_CHECKSUM = -2
DHT_ERROR_ARGUMENT = -3
DHT_ERROR_GPIO     = -4
TRANSIENT_ERRORS = {DHT_ERROR_CHECKSUM, DHT_ERROR_TIMEOUT}

-- Define sensor type constants.
DHT11  = 11
DHT22  = 22
AM2302 = 22
SENSORS = {DHT11, DHT22, AM2302}

local function get_platform()


	plat = platform.platform_detect()	

	if plat == platform.RASPBERRY_PI then	
		
		-- Check for version 1 or 2 of the pi.
		version = platform.pi_version()		
				
		if version == 1 then		
			--return Raspberry_Pi_module
			assert('No driver for Pi 1 yet!')				
		elseif version == 2 then	
			return Raspberry_Pi_2		
		else 
			assert('No driver for detected Raspberry Pi version available!')			
		end
	else	
		assert('Unknown platform.')
	end

end

function valueExists(tbl, value)
  for k,v in pairs(tbl) do
    if value == v then
      return true
    end
  end

  return false
end	

function readSensor(sensor, pin, platform)
	--[[""Read DHT sensor of specified sensor type (DHT11, DHT22, or AM2302) on 
	specified pin and return a tuple of humidity (as a floating point value
	in percent) and temperature (as a floating point value in Celsius). Note that
	because the sensor requires strict timing to read and Linux is not a real
	time OS, a result is not guaranteed to be returned!  In some cases this will
	return the tuple (None, None) which indicates the function should be retried.
	Also note the DHT sensor cannot be read faster than about once every 2 seconds.
	Platform is an optional parameter which allows you to override the detected
	platform interface--ignore this parameter unless you receive unknown platform
	errors and want to override the detection.
	""" ]]--
	if not valueExists(SENSORS, sensor) then
		assert('Expected DHT11, DHT22, or AM2302 sensor value.')
	end
	
	if not platform then
		platform = get_platform()
	end	
	return platform.readSensor(sensor, pin)
	
end	
	
function read_retry(sensor, pin, retries, delay_seconds, platform)
	--[["""Read DHT sensor of specified sensor type (DHT11, DHT22, or AM2302) on 
	specified pin and return a tuple of humidity (as a floating point value
	in percent) and temperature (as a floating point value in Celsius).
	Unlike the read function, this read_retry function will attempt to read
	multiple times (up to the specified max retries) until a good reading can be 
	found. If a good reading cannot be found after the amount of retries, a tuple
	of (None, None) is returned. The delay between retries is by default 2
	seconds, but can be overridden.
	""" ]]--
	
	retries = retries or 15
	delay_seconds = delay_seconds or 2 
	
	for i = 1,retries  do
		humidity, temperature = readSensor(sensor, pin, platform)
		if humidity and temperature then 
			return humidity, temperature
		end	
		sleep(delay_seconds)
	end
	
	return nil, nil	

end	

function sleep(s)
  local ntime = os.time() + s
  repeat until os.time() > ntime
end


return common
