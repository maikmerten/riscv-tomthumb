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

// implementation lifted from Clifford Wolf's PicoRV32 stdlib.c
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
		printf_c(*(--p));
	}
}

// implementation lifted from Clifford Wolf's PicoRV32 stdlib.c
int printf(const char *format, ...) {
	int i;
	va_list ap;

	va_start(ap, format);

	for (i = 0; format[i]; i++) {
		if (format[i] == '%') {
			while (format[++i]) {
				if (format[i] == 'c') {
					printf_c(va_arg(ap,int));
					break;
				}
				if (format[i] == 's') {
					printf_s(va_arg(ap,char*));
					break;
				}
				if (format[i] == 'd') {
					printf_d(va_arg(ap,int));
					break;
				}
			}
		} else {
			printf_c(format[i]);
		}
	}

	va_end(ap);
}


