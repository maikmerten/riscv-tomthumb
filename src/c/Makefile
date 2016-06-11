CC=riscv32-unknown-elf-gcc
CFLAGS=-I./libtomthumb -march=RV32IXcustom -static -nostdlib -Os -fPIC
LDFLAGS=-L./libtomthumb -ltomthumb -Tlink.ld

DUMP=riscv32-unknown-elf-objdump
COPY=riscv32-unknown-elf-objcopy

all: test-libtomthumb.bin

%.bin: %.elf
	$(COPY) -O binary $< $@

%.elf: %.o
	$(CC) $(CFLAGS) -o $@ crt0.s $< $(LDFLAGS)
	$(DUMP) -d $@

%.o: %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -rf *.o *.elf *.bin
