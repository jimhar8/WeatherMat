
# Makefile template for shared library
# gcc -Wall -std=gnu99 -shared -fPIC -o pi2driver.so -I/usr/include/lua5.2 -llua5.2 _Raspberry_Pi_2_Driver.c Raspberry_Pi_2/pi_2_dht_read.c common_dht_read.c Raspberry_Pi_2/pi_2_mmio.c

all:
	gcc -Wall -std=gnu99 -shared -fPIC -o pi2driver.so -I/usr/include/lua5.2 -llua5.2 lua_dht_pi2.c pi_2_dht_read.c common_dht_read.c pi_2_mmio.c
	
clean: 

	rm -f *.so* *.o 

