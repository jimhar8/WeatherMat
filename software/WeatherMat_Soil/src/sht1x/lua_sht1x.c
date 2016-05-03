// Copyright (c) 2014 Adafruit Industries
// Author: Tony DiCola

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <lua.h>                               /* Always include this */
#include <lauxlib.h>                           /* Always include this */
#include <lualib.h>                            /* Always include this */

#include <bcm2835.h>
#include <stdio.h>
#include "RPi_SHT1x.h"



static int sht1x_read(lua_State *L){                /* Internal name of func */

    unsigned char noError = 1;
    value humi_val,temp_val;

    int result = 0;
    
    //Initialise the Raspberry Pi GPIO
    if(!bcm2835_init())
        return 1;
    
        // Wait at least 11ms after power-up (chapter 3.1)
    delay(20); 
    
    
    // Set up the SHT1x Data and Clock Pins
    SHT1x_InitPins();
    
    
    // Reset the SHT1x
    SHT1x_Reset();
    
    
    // Request Temperature measurement
    noError = SHT1x_Measure_Start( SHT1xMeaT );
    if (!noError) {
        
        return 1;
        }
        
    
    // Read Temperature measurement
    noError = SHT1x_Get_Measure_Value( (unsigned short int*) &temp_val.i );
    if (!noError) {
        return 1;
        }
        
        

    // Request Humidity Measurement
    noError = SHT1x_Measure_Start( SHT1xMeaRh );
    if (!noError) {
        return 1;
        }
        
        
        
    // Read Humidity measurement
    noError = SHT1x_Get_Measure_Value( (unsigned short int*) &humi_val.i );
    if (!noError) {
        return 1;
        }
        
        

    // Convert intergers to float and calculate true values
    temp_val.f = (float)temp_val.i;
    humi_val.f = (float)humi_val.i;
    
    
    
    // Calculate Temperature and Humidity
    SHT1x_Calc(&humi_val.f, &temp_val.f);

    //Print the Temperature to the console
    //printf("Temperature: %0.2f%cC\n",temp_val.f,0x00B0);

    //Print the Humidity to the console
    //printf("Humidity: %0.2f%%\n",humi_val.f);
    //Calculate and print the Dew Point
    float fDewPoint;
    SHT1x_CalcDewpoint(humi_val.f ,temp_val.f, &fDewPoint);
    //printf("Dewpoint: %0.2f%cC\n",fDewPoint,0x00B0);  
    
    lua_pushnumber(L, result);
    lua_pushnumber(L,temp_val.f);       /* Push the return */
    lua_pushnumber(L,humi_val.f);       /* Push second return */
    lua_pushnumber(L,fDewPoint);        /* Push third return */
    
    return 4;                              /* Four return values */
}


/* http://www.troubleshooters.com/codecorn/lua/lua_lua_calls_c.htm
 * Register this file's functions with the
 * luaopen_libraryname() function, where libraryname
 * is the name of the compiled .so output. In other words
 * it's the filename (but not extension) after the -o
 * in the cc command.
 *
 * So for instance, if your cc command has -o power.so then
 * this function would be called luaopen_power().
 *
 * This function should contain lua_register() commands for
 * each function you want available from Lua.
 *
*/
int luaopen_sht1x(lua_State *L){
    lua_register(
            L,               /* Lua state variable */
            "readsht1x",        /* func name as known in Lua */
            sht1x_read          /* func name in this file */
            );  
    return 0;
}
