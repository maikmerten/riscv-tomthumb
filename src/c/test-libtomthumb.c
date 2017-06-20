#include <libtomthumb.h>


void main() {
	int i = 0;
	char color = 0xF0;

	set_printf_target(PRINTF_TARGET_SERIAL | PRINTF_TARGET_VGA);

	while(1) {
		set_printf_color(color);

		printf("Serious greetz to %s!\n\r", "CCC Cologne");
		printf("This runs on a RISC-V CPU on a FPGA!\n\r");
		printf("This was greetz no. %d!\n\r\n\r", i);

		for(int i = 0; i < 40; ++i) {
			printf("#");
			wasteTime(40000);
		}


		printf("\n\r\n\r");

		i++;
		color++;
	}
}



void wasteTime(int iterations) {
	for(int i = 0; i < iterations; ++i) {
		volatile char* addr = (char*) (0x30000000);
		char val = *addr;
		*addr = val;
	}
}

