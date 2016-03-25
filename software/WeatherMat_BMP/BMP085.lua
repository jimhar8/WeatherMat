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


local logging = require "logging"
local LuaI2C = require "LuaI2C"
local bit = require("bit")
local socket = require("socket")


-- # BMP085 default address.
BMP085_I2CADDR           = 0x77

-- # Operating Modes
BMP085_ULTRALOWPOWER     = 0
BMP085_STANDARD          = 1
BMP085_HIGHRES           = 2
BMP085_ULTRAHIGHRES      = 3

-- # BMP085 Registers
BMP085_CAL_AC1           = 0xAA  --# R   Calibration data (16 bits)
BMP085_CAL_AC2           = 0xAC  --# R   Calibration data (16 bits)
BMP085_CAL_AC3           = 0xAE  --# R   Calibration data (16 bits)
BMP085_CAL_AC4           = 0xB0  --# R   Calibration data (16 bits)
BMP085_CAL_AC5           = 0xB2  --# R   Calibration data (16 bits)
BMP085_CAL_AC6           = 0xB4  --# R   Calibration data (16 bits)
BMP085_CAL_B1            = 0xB6  --# R   Calibration data (16 bits)
BMP085_CAL_B2            = 0xB8  --# R   Calibration data (16 bits)
BMP085_CAL_MB            = 0xBA  --# R   Calibration data (16 bits)
BMP085_CAL_MC            = 0xBC  --# R   Calibration data (16 bits)
BMP085_CAL_MD            = 0xBE  --# R   Calibration data (16 bits)
BMP085_CONTROL           = 0xF4
BMP085_TEMPDATA          = 0xF6
BMP085_PRESSUREDATA      = 0xF6

-- # Commands
BMP085_READTEMPCMD       = 0x2E
BMP085_READPRESSURECMD   = 0x34

local BMP085 = {}
BMP085.__index = BMP085


setmetatable(BMP085, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

function BMP085.new(mode, address, i2c, ...)

	local self = setmetatable({}, BMP085)

	self.logger = logging.new(function(self, level, message)
							 print(level, message)
							 return true
						   end)


	self.logger:setLevel (logging.DEBUG)
	self.logger:log(logging.DEBUG, "Initializing BMP085")

	mode = mode or BMP085_STANDARD
	address = address or BMP085_I2CADDR
	i2c = i2c or "/dev/i2c-1"

	-- Check that mode is valid.
	local modes = Set{BMP085_ULTRALOWPOWER, BMP085_STANDARD, BMP085_HIGHRES, BMP085_ULTRAHIGHRES}

	if not modes[mode] then
	error (string.format('Unexpected mode value %d.  Set mode to one of BMP085_ULTRALOWPOWER, BMP085_STANDARD, BMP085_HIGHRES, or BMP085_ULTRAHIGHRES', mode))
	end

	self.mode = mode
	
	
	-- Create I2C device.
	self.device = LuaI2C(address, i2c, self.logger)

	--Load calibration values.
	self:load_calibration() 
	
	return self
  
end


function BMP085:load_calibration()

		self.cal_AC1 = self.device:readS16BE(BMP085_CAL_AC1)   --# INT16
		self.cal_AC2 = self.device:readS16BE(BMP085_CAL_AC2)   --# INT16
		self.cal_AC3 = self.device:readS16BE(BMP085_CAL_AC3)   --# INT16
		self.cal_AC4 = self.device:readU16BE(BMP085_CAL_AC4)   --# UINT16
		self.cal_AC5 = self.device:readU16BE(BMP085_CAL_AC5)   --# UINT16
		self.cal_AC6 = self.device:readU16BE(BMP085_CAL_AC6)  -- # UINT16
		self.cal_B1 = self.device:readS16BE(BMP085_CAL_B1)    -- # INT16
		self.cal_B2 = self.device:readS16BE(BMP085_CAL_B2)     --# INT16
		self.cal_MB = self.device:readS16BE(BMP085_CAL_MB)     --# INT16
		self.cal_MC = self.device:readS16BE(BMP085_CAL_MC)     --# INT16
		self.cal_MD = self.device:readS16BE(BMP085_CAL_MD)    -- # INT16
		
		-- self:load_datasheet_calibration()
		
		self.logger:log(logging.DEBUG, string.format('AC1 = %d', self.cal_AC1))
		self.logger:log(logging.DEBUG, string.format('AC2 = %d', self.cal_AC2))
		self.logger:log(logging.DEBUG, string.format('AC3 = %d', self.cal_AC3))
		self.logger:log(logging.DEBUG, string.format('AC4 = %d', self.cal_AC4))
		self.logger:log(logging.DEBUG, string.format('AC5 = %d', self.cal_AC5))
		self.logger:log(logging.DEBUG, string.format('AC6 = %d', self.cal_AC6))
		self.logger:log(logging.DEBUG, string.format('B1 = %d', self.cal_B1))
		self.logger:log(logging.DEBUG, string.format('B2 = %d', self.cal_B2))
		self.logger:log(logging.DEBUG, string.format('MB = %d', self.cal_MB))
		self.logger:log(logging.DEBUG, string.format('MC = %d', self.cal_MC))
		self.logger:log(logging.DEBUG, string.format('MD = %d', self.cal_MD))
		

end


function BMP085:load_datasheet_calibration()

	-- # Set calibration from values in the datasheet example.  Useful for debugging the
	-- # temp and pressure calculation accuracy.

	self.cal_AC1 = 408
	self.cal_AC2 = -72
	self.cal_AC3 = -14383
	self.cal_AC4 = 32741
	self.cal_AC5 = 32757
	self.cal_AC6 = 23153
	self.cal_B1 = 6190
	self.cal_B2 = 4
	self.cal_MB = -32767
	self.cal_MC = -8711
	self.cal_MD = 2868

end

function BMP085:read_raw_temp()

	-- """Reads the raw (uncompensated) temperature from the sensor."""
	
	self.device:write8(BMP085_CONTROL, BMP085_READTEMPCMD)
	socket.sleep(0.005)	
	raw = self.device:readU16BE(BMP085_TEMPDATA)
	
	self.logger:log(logging.DEBUG, string.format('Raw temp 0x%04x (%d)', bit.band(raw, 0xFFFF), raw))
	
	return raw

end


function BMP085:read_raw_pressure()
	--"""Reads the raw (uncompensated) pressure level from the sensor."""
	self.device:write8(BMP085_CONTROL, BMP085_READPRESSURECMD + (bit.lshift(self.mode , 6)))
	if self.mode == BMP085_ULTRALOWPOWER then
		socket.sleep(0.005)	
	elseif self.mode == BMP085_HIGHRES then
		socket.sleep(0.014)	
	elseif self.mode == BMP085_ULTRAHIGHRES then
		socket.sleep(0.026)	
	else
		socket.sleep(0.008)
	end	
		
	msb = self.device:readU8(BMP085_PRESSUREDATA)
	lsb = self.device:readU8(BMP085_PRESSUREDATA+1)
	xlsb = self.device:readU8(BMP085_PRESSUREDATA+2)

	raw = bit.arshift(bit.lshift(msb, 16) + bit.lshift(lsb, 8) + xlsb, 8 - self.mode)
	
	self.logger:log(logging.DEBUG, string.format('Raw pressure 0x%04x (%d)', bit.band(raw, 0xFFFF), raw))
	return raw
	
end	


function BMP085:read_temperature()
	--"""Gets the compensated temperature in degrees celsius."""
	UT = self:read_raw_temp()
	--# Datasheet value for debugging:
	--#UT = 27898
	--# Calculations below are taken straight from section 3.5 of the datasheet.

	X1 = bit.arshift((UT - self.cal_AC6) * self.cal_AC5 , 15)
	X2 = bit.lshift(self.cal_MC, 11) / (X1 + self.cal_MD)
	B5 = X1 + X2
	temp = (bit.arshift((B5 + 8), 4)) / 10.0
	
	temp = temp * 9.0 / 5.0 + 32

	self.logger:log(logging.DEBUG, string.format('Calibrated temperature (%4.1f) F', temp))
	
	return temp
	
end

function BMP085:read_pressure()
		-- """Gets the compensated pressure in Pascals."""
		
		UT = self:read_raw_temp()
		UP = self:read_raw_pressure()
		
		--# Datasheet values for debugging:
		-- #UT = 27898
		-- #UP = 23843
		--# Calculations below are taken straight from section 3.5 of the datasheet.
		--# Calculate true temperature coefficient B5.
	
		X1 = bit.arshift((UT - self.cal_AC6) * self.cal_AC5, 15)	
		X2 = (bit.lshift(self.cal_MC , 11)) / (X1 + self.cal_MD)	
		B5 = X1 + X2
		self.logger:log(logging.DEBUG, string.format('B5 = %d', B5))
		
		--# Pressure Calculations				
		B6 = B5 - 4000
		self.logger:log(logging.DEBUG, string.format('B6 = %d', B6))
		
		X1 = bit.arshift((self.cal_B2 * bit.arshift((B6 * B6) , 12)) , 11)
		X2 = bit.arshift((self.cal_AC2 * B6) , 11)
		X3 = X1 + X2
	
		B3 = ((bit.lshift((self.cal_AC1 * 4 + X3) , self.mode)) + 2) / 4
			
		self.logger:log(logging.DEBUG, string.format('B3 = %d', B3))	
		
		X1 = bit.arshift((self.cal_AC3 * B6) , 13)
		X2 = bit.arshift((self.cal_B1 * (bit.arshift((B6 * B6) , 12))) , 16)
		X3 = bit.arshift(((X1 + X2) + 2) , 2)
		B4 = bit.arshift((self.cal_AC4 * (X3 + 32768)) , 15)
		self.logger:log(logging.DEBUG, string.format('B4 = %d', B4))
		
		B7 = (UP - B3) * bit.arshift(50000 , self.mode)
		self.logger:log(logging.DEBUG, string.format('B7 = %d', B7))
		
		if B7 < 0x80000000 then
			p = (B7 * 2) / B4
		else	
			p = (B7 / B4) * 2
		end	
		
		X1 = bit.arshift(p , 8) * bit.arshift(p , 8)
		X1 = bit.arshift((X1 * 3038) , 16)
		X2 = bit.arshift((-7357 * p) , 16)
		p = p + bit.arshift((X1 + X2 + 3791) , 4)		
	
		self.logger:log(logging.DEBUG, string.format('Pressure %f in Hg', p))
		return p
		
end	

function BMP085:read_altitude(sealevel_pa)
	--"""Calculates the altitude in meters."""
	--# Calculation taken straight from section 3.6 of the datasheet.
	
	sealevel_pa = sealevel_pa or 101325.0
	
	pressure = self:read_pressure()
	altitude = 44330.0 * (1.0 - ((pressure / sealevel_pa) ^ (1.0/5.255))) * 3.28084

	self.logger:log(logging.DEBUG, string.format('Altitude %f ft', altitude))
	return altitude	
	
end	


function BMP085:read_sealevel_pressure(altitude_m)
	--"""Calculates the pressure at sealevel when given a known altitude in
	--meters. Returns a value in Pascals."""
	
	altitude_m = altitude_m or 0.0
	
	pressure = self:read_pressure()
	
	p0 = pressure / ((1.0 - altitude_m / 44330.0) ^ 5.255)
	
	self.logger:log(logging.DEBUG, string.format('Sealevel pressure %f Pa', p0))
	
	return p0
	
end
		
local instance = BMP085(BMP085_STANDARD, "/dev/i2c-1", 0x77)
-- instance:read_raw_temp()
--instance:read_raw_pressure()
instance:read_temperature()
instance:read_pressure()	
instance:read_sealevel_pressure(441.0)		




