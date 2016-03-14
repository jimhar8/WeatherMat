#!/usr/bin/lua
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

--]]

package.path = package.path .. ';../Lua_DHT/?.lua'

require("common")
require("platform")
require("Raspberry_Pi_2")
require("pi2driver")

local function valueExists(tbl, value)
  for k,v in pairs(tbl) do
    if value == v then
      return true
    end
  end

  return false
end	


local sensor_args = {}

-- Parse command line parameters.
sensor_args = { ['11'] = 11, ['22'] = 22, ['2302'] = 22}


if #arg == 2 and valueExists(sensor_args, tonumber(arg[1])) then
	sensor = sensor_args[arg[1]]
	pin = arg[2]
else
	print ('usage: sudo ./LuaDHT.py [11|22|2302] GPIOpin#')
	print ('example: sudo ./LuaDHT.py 2302 4 - Read from an AM2302 connected to GPIO #4')
	os.exit()
end	

-- Try to grab a sensor reading.  Use the read_retry method which will retry up
-- to 15 times to get a sensor reading (waiting 2 seconds between each retry).
humidity, temperature = read_retry(sensor, pin)

-- Un-comment the line below to convert the temperature to Fahrenheit.

if temperature then
	temperature = temperature * 9/5.0 + 32
end	

-- Note that sometimes you won't get a reading and
-- the results will be null (because Linux can't
-- guarantee the timing of calls to read the sensor).  
-- If this happens try again!
if humidity and temperature then
	local msg = ""
	
	msg = string.format('Temp=%.1f deg  Humidity=%.1f%%', temperature, humidity) 
	print (msg)
else
	print ('Failed to get reading. Try again!')
	os.exit()
end	

	
