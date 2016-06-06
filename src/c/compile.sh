#!/bin/bash
COMPILE="riscv32-unknown-elf-gcc -static -nostdlib -Os -fPIC -Tlink.ld"
DUMP="riscv32-unknown-elf-objdump"
COPY="riscv32-unknown-elf-objcopy"

$COMPILE -o $1 crt0.s $1.c && $DUMP -d $1 && $COPY -O binary $1 $1.bin
