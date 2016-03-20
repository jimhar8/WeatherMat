
local dir_table = {

    {dir_deg = 0.0, dir = "N", resistance = 33000.0}, 
    {dir_deg = 22.5, dir = "NNE", resistance = 6570.0}, 
    {dir_deg = 45.0, dir = "NE", resistance = 8200.0}, 
    {dir_deg = 67.5, dir = "ENE", resistance = 891.0}, 
    {dir_deg = 90.0, dir = "E", resistance = 1000.0}, 
    {dir_deg = 112.5, dir = "ESE", resistance = 688.0}, 
    {dir_deg = 135.0, dir = "SE", resistance = 2200.0}, 
    {dir_deg = 157.5, dir = "SSE", resistance = 1410.0}, 
    {dir_deg = 180.0, dir = "S", resistance = 3900.0},
    {dir_deg = 202.5, dir = "SSW", resistance = 3140.0},
    {dir_deg = 225.0, dir = "SW", resistance = 16000.0},
    {dir_deg = 247.5, dir = "WSW", resistance = 14120.0},
    {dir_deg = 270.0, dir = "W", resistance = 120000.0},
    {dir_deg = 292.5, dir = "WNW", resistance = 42120.0},
    {dir_deg = 315.0, dir = "NW", resistance = 64900.0},
    {dir_deg = 337.5, dir = "NNW", resistance = 21800.0}

}

local tolerance = 0.01
local voltage_rail = 3.30
local res_divider = 10000.0

local function get_direction(adc_count)

    local volt_reading = voltage_rail * adc_count / 1023.0
    --print("voltage reading", volt_reading)
    
   
    for _, element in ipairs(dir_table) do 
    
        local exp_voltage = voltage_rail * element.resistance / (element.resistance + res_divider)       
        
        if (volt_reading <= (exp_voltage + tolerance) and volt_reading >= (exp_voltage - tolerance)) then
        
            --print("exp voltage", exp_voltage)
        
            --print("found element", element.dir)            
            return element.dir            
        end
    
    
    end    
    
    return nil
end

-- need adc count call

for j = 0,1023 do

    local result = get_direction(j)
    --print("j", j)
    
    if result then
        print("direction is", result)
    else
        --print("could not find direction")
    end

end

--local result = get_direction(770)



