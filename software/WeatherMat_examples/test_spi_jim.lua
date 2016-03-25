--
-- lua-periphery by vsergeev
-- https://github.com/vsergeev/lua-periphery
-- License: MIT
--

--require('test')
local periphery = require('periphery')
local SPI = periphery.SPI

local spi = SPI("/dev/spidev0.0", 0, 5e4)

local data_out = {0x01, 0x00, 0x00}
local data_in = spi:transfer(data_out)

--print(string.format("shifted out {0x%02x, 0x%02x, 0x%02x}", unpack(data_out)))
print(string.format("shifted in  {0x%02x, 0x%02x, 0x%02x}", unpack(data_in)))

spi:close()
