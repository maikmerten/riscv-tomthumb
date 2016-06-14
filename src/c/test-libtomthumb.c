#include <libtomthumb.h>


void main() {
	int i = 0;
	char color = 0xF0;

	set_printf_target(PRINTF_TARGET_SERIAL | PRINTF_TARGET_VGA);

	while(1) {
		set_printf_color(color);
		printf("Hi there. This is a name: '%s'\n\r", "Hans");
		printf("Number: %d   another one: %d\n\r", -1337, i);
		printf("This printf has no argument\n\r");
		printf("Another number: %d\n\r", -i);
		i++;
		color++;
	}
}
