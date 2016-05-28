#include <stdarg.h>

#define SERIAL_DATA   *((volatile char*)0x20000000)
#define SERIAL_RREADY *((volatile char*)0x20000001)
#define SERIAL_WREADY *((volatile char*)0x20000002)

void printf_c(char c) {
	// wait until serial interface is ready to transmit
	while(!SERIAL_WREADY){};
	// write character
	SERIAL_DATA = c;
}


void printf_s(char* s) {
	while(*s) printf_c(*(s++));
}

void printf_d(int i) {
	char buf[16];
	char *p = buf;

	// output sign for negative input
	if(i < 0) {
		printf_c('-');
		i *= -1;
	}

	while(i > 0 || p == buf) {
		// put lowest decimal digit into buffer
		*(p++) = (char)('0' + (i % 10));
		// shift right by one decimal digit
		i /= 10;
	}

	// output buffer, highest digits first
	while(p != buf) {
		p -= 1;
		printf_c(*p);
	}
}


