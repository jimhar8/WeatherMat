-- #
-- # Permission is hereby granted, free of charge, to any person obtaining a copy
-- # of this software and associated documentation files (the "Software"), to deal
-- # in the Software without restriction, including without limitation the rights
-- # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- # copies of the Software, and to permit persons to whom the Software is
-- # furnished to do so, subject to the following conditions:
-- #
-- # The above copyright notice and this permission notice shall be included in
-- # all copies or substantial portions of the Software.
-- #
-- # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- # THE SOFTWARE.
-- import logging
-- import time

package.path = package.path .. ';../WeatherMat_common/?.lua'
package.cpath = package.cpath .. ';../WeatherMat_common/msleep/?.so'

local logging = require "logging"
local LuaI2C = require "LuaI2C"
local bit = require("bit")
require("msleep")

-- # TSL2591 default address.
TSL2591_I2CADDR           = 0x29

VISIBLE = 2  -- channel 0 - channel 1
INFRARED = 1  -- channel 1
FULLSPECTRUM = 0  -- channel 0

ADDR = 0x29
READBIT = 0x01
COMMAND_BIT = 0xA0  --# bits 7 and 5 for 'command normal'
CLEAR_BIT = 0x40  --# Clears any pending interrupt (write 1 to clear)
WORD_BIT = 0x20  --# 1 = read/write word (rather than byte)
BLOCK_BIT = 0x10  --# 1 = using block read/write
ENABLE_POWERON = 0x01
ENABLE_POWEROFF = 0x00
ENABLE_AEN = 0x02
ENABLE_AIEN = 0x10
CONTROL_RESET = 0x80
LUX_DF = 408.0
LUX_COEFB = 1.64  --# CH0 coefficient
LUX_COEFC = 0.59  --# CH1 coefficient A
LUX_COEFD = 0.86  --# CH2 coefficient B

REGISTER_ENABLE = 0x00
REGISTER_CONTROL = 0x01
REGISTER_THRESHHOLDL_LOW = 0x02
REGISTER_THRESHHOLDL_HIGH = 0x03
REGISTER_THRESHHOLDH_LOW = 0x04
REGISTER_THRESHHOLDH_HIGH = 0x05
REGISTER_INTERRUPT = 0x06
REGISTER_CRC = 0x08
REGISTER_ID = 0x0A
REGISTER_CHAN0_LOW = 0x14
REGISTER_CHAN0_HIGH = 0x15
REGISTER_CHAN1_LOW = 0x16
REGISTER_CHAN1_HIGH = 0x17


-- GAIN_LOW = 0x00  --# low gain (1x)
-- GAIN_MED = 0x10  --# medium gain (25x)
-- GAIN_HIGH = 0x20  --# medium gain (428x)
-- GAIN_MAX = 0x30  --# max gain (9876x)


local TSL2591 = {}
TSL2591.__index = TSL2591


TSL2591.integration = {[100] = 0x00, [200] = 0x01, [300] = 0x02, 
    [400] = 0x03, [500] = 0x04, [600] = 0x05 }
    
TSL2591.gain = {GAIN_LOW = 0x00, GAIN_MED = 0x10, GAIN_HIGH = 0x20, GAIN_MAX = 0x30}

TSL2591.channel = {FULLSPECTRUM = 0, INFRARED = 1, VISIBLE = 2}

setmetatable(TSL2591, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

function TSL2591.new(address, i2c, intTime, gain, ...)

	local self = setmetatable({}, TSL2591)

	self.logger = logging.new(function(self, level, message)
							 print(level, message)
							 return true
						   end)
						   
						   
   
	self.logger:setLevel (logging.DEBUG)
	self.logger:log(logging.DEBUG, "Initializing TSL2591") 

	address = address or TSL2591_I2CADDR
	i2c = i2c or "/dev/i2c-1"    
    
    -- Create I2C device.
	self.device = LuaI2C(address, i2c, self.logger)
						   
    self.integration_time_byte = TSL2591.integration[intTime]
    self.integration_time = intTime
    
	self.gain = gain
    
    self:set_timing(self.integration_time)
    self:set_gain(self.gain)    
    self:disable() -- to be sure

	
	return self
  
end


function TSL2591:set_timing(integration)

	self:enable()
	self.integration_time = integration
    
    self.device:write8(bit.bor(COMMAND_BIT, REGISTER_CONTROL),
		bit.bor(self.integration_time_byte, TSL2591.gain[self.gain]))
	
	self:disable()

end

function TSL2591:get_timing()

	return self.integration_time_byte

end

function TSL2591:set_gain(gain)

	self:enable()
	self.gain = gain
	
	self.device:write8(bit.bor(COMMAND_BIT, REGISTER_CONTROL),
		bit.bor(self.integration_time_byte, TSL2591.gain[self.gain]))
	
	self:disable()

end

function TSL2591:get_gain()

	return self.gain

end

function TSL2591:calculate_lux(full, ir)

	-- check for overflow conditions first
	
	if (full == 0xFFFF) or (ir == 0xFFFF) then
		return 0
    end
		
	atime = self.integration_time	
    
    if self.gain == "GAIN_LOW" then
        again = 1.0
    elseif self.gain == "GAIN_MED" then
        again = 25.0
    elseif self.gain == "GAIN_HIGH" then
        again = 428.0   
    else -- GAIN_MAX
        again = 9876.0
    end
    

	--# cpl = (ATIME * AGAIN) / DF
	cpl = (atime * again) / LUX_DF
	lux1 = (full - (LUX_COEFB * ir)) / cpl

	lux2 = ((LUX_COEFC * full) - (LUX_COEFD * ir)) / cpl

    --# The highest value is the approximate lux equivalent
	if lux1 >= lux2 then 
		return lux1
	else
		return lux2
	end
end

 

function TSL2591:enable()

	self.device:write8(bit.bor(COMMAND_BIT, REGISTER_ENABLE),
		bit.bor(bit.bor(ENABLE_POWERON, ENABLE_AEN), ENABLE_AIEN))
end

function TSL2591:disable()

	self.device:write8(bit.bor(COMMAND_BIT, REGISTER_ENABLE),
		ENABLE_POWEROFF)
end

function TSL2591:get_full_luminosity()

	self:enable()
	msleep(1.2 * self.integration_time)
	
	full = self.device:readU16LE(bit.bor(COMMAND_BIT, REGISTER_CHAN0_LOW))
	ir = self.device:readU16LE(bit.bor(COMMAND_BIT, REGISTER_CHAN1_LOW))
	
	self:disable()
	
	return full, ir
	
	
end

function TSL2591:get_luminosity(channel) 
	
	full, ir = self:get_full_luminosity()
	
	if channel == FULLSPECTRUM then
		return full
	elseif channel == INFRARED then
		return ir
	elseif channel == VISIBLE then
		return (full - ir)
	else
		return 0
	end

end 
  
  
		
local instance = TSL2591("/dev/i2c-1", 0x29, 100, "GAIN_MED")
full, ir = instance:get_full_luminosity() 
lux = instance:calculate_lux(full, ir)

print (string.format('Lux = %f  full = %i  ir = %i', lux, full, ir))
-- instance:read_raw_temp()





