
# Makefile template for shared library
# gcc -Wall -std=gnu99 -shared -fPIC -o pi2driver.so -I/usr/include/lua5.2 -llua5.2 _Raspberry_Pi_2_Driver.c Raspberry_Pi_2/pi_2_dht_read.c common_dht_read.c Raspberry_Pi_2/pi_2_mmio.c

all:
	#gcc -o SHT1x.so lua_sht1x.c RPi_SHT1x.c -l bcm2835 -lm
	gcc -Wall -std=gnu99 -shared -fPIC -o sht1x.so -I/usr/include/lua5.2 -llua5.2 lua_sht1x.c RPi_SHT1x.c -l bcm2835 -lm
	
clean: 

	rm -f *.so* *.o 

