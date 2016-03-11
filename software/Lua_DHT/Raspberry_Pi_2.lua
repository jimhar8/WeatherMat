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

]]--

local Raspberry_Pi_2 = {}

package.cpath  = package.cpath .. ';../Lua_DHT/?.so'

function Raspberry_Pi_2.readSensor(sensor, pin) 

	--# Validate pin is a valid GPIO.
	if not pin or tonumber(pin) < 0 or tonumber(pin) > 31 then 
		assert('Pin must be a valid GPIO number 0 to 31.')
	--# Get a reading from C driver code.
	end
	result, humidity, temp = readdht(sensor, tonumber(pin))
	if valueExists(TRANSIENT_ERRORS, result) then
		--# Signal no result could be obtained, but the caller can retry.
		return nil, nil
	elseif result == DHT_ERROR_GPIO then
		assert('Error accessing GPIO. Make sure program is run as root with sudo!')
	elseif result ~= DHT_SUCCESS then
		--# Some kind of error occured.
		--raise RuntimeError('Error calling DHT test driver read: {0}'.format(result))
		assert('Error calling DHT test driver read')
	end	
	return humidity, temp
end


return Raspberry_Pi_2



