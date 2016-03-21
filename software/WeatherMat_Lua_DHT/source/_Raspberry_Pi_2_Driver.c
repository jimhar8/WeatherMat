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

#include "Raspberry_Pi_2/pi_2_dht_read.h"



static int Raspberry_Pi_2_Driver_read(lua_State *L){                /* Internal name of func */

	// Call dht_read and return result code, humidity, and temperature.
    float humidity = 0, temperature = 0;
	int sensor = 0, pin = 0;
	int result = 0;
	
	
	sensor = lua_tonumber(L, 1);
	pin = lua_tonumber(L, 2);	
	
	printf("sensor=%d\n",sensor);
	printf("portpin=%d\n",pin);
	
	result = pi_2_dht_read(sensor, pin, &humidity, &temperature);

	lua_pushnumber(L, result);
	lua_pushnumber(L,humidity);      	/* Push the return */
	lua_pushnumber(L,temperature);      /* Push second return */
	
	return 3;                              /* Three return values */
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
int luaopen_pi2driver(lua_State *L){
	lua_register(
			L,               /* Lua state variable */
			"readdht",        /* func name as known in Lua */
			Raspberry_Pi_2_Driver_read          /* func name in this file */
			);  
	return 0;
}
