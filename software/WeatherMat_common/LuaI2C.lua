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

--jjh: class derivation seems to be from http://lua-users.org/wiki/ObjectOrientationTutorial


local logging = require "logging"
local bit = require("bit")
local I2C = require('periphery').I2C

local LuaI2C = {}
LuaI2C.__index = LuaI2C

setmetatable(LuaI2C, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local device = nil


function LuaI2C.new(devAddress, i2cAddress, logger)

	local self = setmetatable({}, LuaI2C)

	if not logger then

	  self.logger = logging.new(function(self, level, message)
								 print(level, message)
								 return true
							   end)  
	  
	  self.logger:setLevel (logging.DEBUG)
	  self.logger:log(logging.DEBUG, "Initializing LuaI2C")

	else

	   self.logger = logger
	   self.logger:log(logging.DEBUG, "Initializing LuaI2C")
	   
	end
	  

	self.devAddress = devAddress or "/dev/i2c-1"
	self.i2cAddress = i2cAddress or 0x77
    
    if device then
        self.logger:log(logging.DEBUG, "Device already opened ") 
    else    
        device = I2C(devAddress)   
    end
    
    self.device = device
    
	return self
  
end


function LuaI2C:close()

  self.device:close()
  
end


function LuaI2C:close()

  self.device:close()
  
end


function LuaI2C:writeRaw8(register, value)

    --"""Write an 8-bit value on the bus (without register)."""	

    value = bit.band(value, 0xFF)
	
	local msgs = { {value} }	
	
	self.device:transfer(self.i2cAddress, msgs)
	
	self.logger:log(logging.DEBUG, string.format("Wrote 0x%02X", value))		
	
end


function LuaI2C:write8(register, value)

    --"""Write an 8-bit value to the specified register."""	

    value = bit.band(value, 0xFF)
	
	local msgs = { {register, value} }	
	
	self.device:transfer(self.i2cAddress, msgs)
	
	self.logger:log(logging.DEBUG, string.format("Wrote 0x%02X to register 0x%02X", value, register))
	
	
end

function LuaI2C:write16(register, value)

    --"""Write a 16-bit value to the specified register."""	

    value = bit.band(value, 0xFFFF)
	
	value_lo = bit.band(value, 0x00FF)
	value_hi = bit.band(bit.rshift(value, 8), 0xFF)
	
	local msgs = { {register, value_lo, value_hi} }	
	
	self.device:transfer(self.i2cAddress, msgs)
	
	self.logger:log(logging.DEBUG, string.format("Wrote 0x%04X to register pair 0x%02X, 0x%02X", value, register, register + 1))
	
	
end


function LuaI2C:readRaw8(register)

	--"""Read an 8-bit value on the bus (without register)."""

    local msgs = { {0x00, flags = I2C.I2C_M_RD} }	
	

    self.device:transfer(self.i2cAddress, msgs)		

	local result = bit.band(msgs[2][1], 0xFF) 
  
    self.logger:log(logging.DEBUG, string.format("Read 0x%02X from register 0x%02X", value, register))	
     
    return result
    
end

function LuaI2C:readU8(register)

	-- """Read an unsigned byte from the specified register."""

    local msgs = { {register}, {0x00, flags = I2C.I2C_M_RD} }	
	
    self.device:transfer(self.i2cAddress, msgs)		

	local result = bit.band(msgs[2][1], 0xFF) 
  
    self.logger:log(logging.DEBUG, string.format("Read 0x%02X from register 0x%02X", result, register))	
     
    return result
    
end

function LuaI2C:readS8(register)

	--"""Read a signed byte from the specified register."""

	local result = self:readU8(register, little_endian)
	
	if result > 127 then
		result = result - 256
	end
	
	return result

end


function LuaI2C:readU16(register, little_endian)

		-- """Read an unsigned 16-bit value from the specified register, with the
        -- specified endianness (default little endian, or least significant byte
        -- first)."""

    local msgs = { {register}, {0x00, 0x00, flags = I2C.I2C_M_RD} }	
	
	if little_endian == nil then
		little_endian = true
	end	

    self.device:transfer(self.i2cAddress, msgs)		
    local value = msgs[2][1] * 256 + tonumber(msgs[2][2])	
  
    self.logger:log(logging.DEBUG, string.format("Read 0x%04X from register pair 0x%02X, 0x%02X", value, register, register + 1))
	
	-- Swap bytes if using big endian because read_word_data assumes little
    -- endian on ARM (little endian) systems.
	
	if little_endian then

		local hiByte = bit.band(value, 0xFF)	
		local loByte = bit.rshift(bit.band(value, 0xFF00), 8)	
		result = hiByte * 256 + loByte		
	
	else	
		result = value		
	end
     
    return result
    
end



function LuaI2C:readS16(register, little_endian)

    --"""Read a signed 16-bit value from the specified register, in big
    --    endian byte order."""
	
	if little_endian == nil then
		little_endian = true
	end	

    result = self:readU16(register, little_endian)
  
    if result > 32767 then
            result = result - 65536
    end      
     
    return result
    
end

function LuaI2C:readU16LE(register)

	-- """Read an unsigned 16-bit value from the specified register, in little
	-- endian byte order."""

    local value = self:readU16(register, true) 	
    return result
end


function LuaI2C:readU16BE(register)

	-- """Read an unsigned 16-bit value from the specified register, in big
	-- endian byte order."""	

    local value = self:readU16(register, false) 	
    return result
end


function LuaI2C:readS16LE(register)

    -- """Read a signed 16-bit value from the specified register, with the
    -- specified endianness (default little endian, or least significant byte
    -- first)."""	

    local value = self:readS16(register, true) 	
    return result
end


function LuaI2C:readS16BE(register)

    -- """Read a signed 16-bit value from the specified register, with the
    -- specified endianness (default little endian, or least significant byte
    -- first)."""	
	

    local value = self:readS16(register, false) 	
    return result
end

return LuaI2C


--local instance = LuaI2C("/dev/i2c-1")

-- instance:write8(0xF4, 0x2E)
-- result = instance:readU16BE(0xF6)
-- print(result)
-- instance:close()


