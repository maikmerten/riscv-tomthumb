#include <stdarg.h>

#define SERIAL_DATA   *((volatile char*)0x20000000)
#define SERIAL_RREADY *((volatile char*)0x20000001)
#define SERIAL_WREADY *((volatile char*)0x20000002)

void printf_c(char c) {
	while(!SERIAL_WREADY){};
	SERIAL_DATA = c;
}


void printf_s(char* s) {
	while(*s) printf_c(*(s++));
}	
