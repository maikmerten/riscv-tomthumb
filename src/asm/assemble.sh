#!/bin/bash
LINK="riscv32-unknown-elf-gcc -O0 -nostdlib -nostartfiles -Tlink.ld"
DUMP="riscv32-unknown-elf-objdump"
COPY="riscv32-unknown-elf-objcopy"

$LINK -o $1 $1.s && $DUMP -d $1 && $COPY -O binary $1 $1.bin
