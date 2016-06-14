#include <stdarg.h>
#include "libtomthumb.h"

#define SERIAL_DATA   *((volatile char*)0x20000000)
#define SERIAL_RREADY *((volatile char*)0x20000001)
#define SERIAL_WREADY *((volatile char*)0x20000002)

#define VGA_COLS 40
#define VGA_ROWS 30
#define VGA_TEXT *((volatile char*)(0x30000000 + vga_offset))
#define VGA_COLOR *((volatile char*)(0x30000800 + vga_offset))

char vga_row, vga_column;
int vga_offset;
char printf_target = PRINTF_TARGET_SERIAL | PRINTF_TARGET_VGA;
char printf_color = 0xF0;


void set_printf_target(char target) {
	printf_target = target;
}

void set_printf_color(char color) {
	printf_color = color;
}

void printf_scroll_line() {
	char text,color;
	// copy row contents from row below
	for(vga_offset = 0; vga_offset < (VGA_ROWS - 1) * VGA_COLS; ++vga_offset) {
		vga_offset += VGA_COLS;
		text = VGA_TEXT;
		color = VGA_COLOR;
		vga_offset -= VGA_COLS;
		VGA_TEXT = text;
		VGA_COLOR = color;
	}

	// clear last line
	for(vga_offset = (VGA_ROWS - 1) * VGA_COLS; vga_offset < VGA_ROWS * VGA_COLS; ++vga_offset) {
		VGA_TEXT = ' ';
		VGA_COLOR = 0;
	}
}

void printf_c(char c) {

	if(printf_target & PRINTF_TARGET_SERIAL) {
		// wait until serial interface is ready to transmit
		while(!SERIAL_WREADY){};
		// write character
		SERIAL_DATA = c;
	}

	if(printf_target & PRINTF_TARGET_VGA) {
		// write to VGA
		if(c == '\n') {
			vga_row += 1;
		} else if(c == '\r') {
			vga_column = 0;
		} else {
			VGA_TEXT = c;
			VGA_COLOR = printf_color;
			vga_column++;
		}


		if(vga_column >= VGA_COLS) {
			vga_column = 0;
			vga_row += 1;
		}
		while(vga_row >= VGA_ROWS) {
			printf_scroll_line();
			vga_row--;
		}

		//vga_offset = vga_row * 40 + vga_column;
		vga_offset = (vga_row << 5) + (vga_row << 3) + vga_column;
	}
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
void printf(const char *format, ...) {
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


