CC=riscv32-unknown-elf-gcc
CFLAGS=-static -nostdlib -Os -fPIC

AR=riscv32-unknown-elf-ar
ARFLAGS=rs

DUMP=riscv32-unknown-elf-objdump

%.o: %.c
	$(CC) $(CFLAGS) -c $<
	$(DUMP) -d $@

libtomthumb.a: libtomthumb.o
	$(AR) $(ARFLAGS) libtomthumb.a libtomthumb.o

clean:
	rm *.o *.a
