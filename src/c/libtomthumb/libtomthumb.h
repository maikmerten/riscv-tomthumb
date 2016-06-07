#ifndef LIBTOMTHUMB
#define LIBTOMTHUMB


#define PRINTF_TARGET_SERIAL 1
#define PRINTF_TARGET_VGA 2
void set_printf_target(char target);
void set_printf_color(char color);

void printf_c(char c);
void printf_s(char* s);
void printf_d(int i);
void printf(const char* format, ...);


#endif
