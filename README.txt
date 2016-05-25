Tom Thumb RISC-V CPU core and demo system
=========================================

This repository contains the VHDL sources for a simple CPU design which executes RV32I RISC-V instructions (http://riscv.org/) and some peripherals for testing. Also included are project files for the Terasic DE0-Nano board (containing an Altera Cyclone IV FPGA) and some programs (mostly assembler) to test the design.

My main motivation for this project is to learn VHDL - the code quality and feature set reflects this. No guarantees! Feel free to use the code in any way you see fit, though (see LICENSE file).

Primary design goals are simplicity of the design and lightness regarding consumption of FPGA resources. Currently, the complete designs fits within ~1600 LEs on a Cyclone IV FPGA, ~1200 LEs being used by the CPU core. The design safely can be clocked at up to ~100 MHz on Cyclone IV devices, although the default configuration for the DE0-Nano board clocks it at merely 50 MHz.

To reflect its design sophistication and technical prowess, the design is named after Tom Thumb, an experimental locomotive design from 1830. https://en.wikipedia.org/wiki/Tom_Thumb_%28locomotive%29


CPU Core
========

src/vhdl/cpu/

The CPU executes the RV32I subset of the RISC-V instruction set. Instructions need several cycles to execute as they progress through following stages:

 * Instruction fetch (FETCH)
 * Instruction decode (DECODE)
 * Register read (REGREAD)
 * Execution on ALU (EXECUTE)
 * Memory stage (MEMORY)
 * Register writeback (REGWRITE)

MEMORY and REGWRITE are skipped for instructions that don't need these stages. After conclusion of the instruction fetch most instructions thus need between three and five additional cycles. Shift operations are slower, with the number of additional cycles being equal to the shift amount (shifts are done one bit position at a time).

The speed of instruction fetch and load/store instructions is highly dependent on the bus interface. Currently, the only CPU interface available implements a Wisbone bus (http://cdn.opencores.org/downloads/wbspec_b4.pdf) with a data width of 8 bit (!) and an address width of 32 bit (bus_wb8.vhd). Four bus cycles are needed to fetch 32 bits, which means that performance is completely dominated by the dozen clock cycles needed to complete instruction fetch. Performance can thus trivially be improved by, e.g., plumbing in a 32-bit bus interface.

Basically, Tom Thumb implements a 2014 instruction set with (at best) 1970ies implementation features ;-)

Interrupts are not currently supported, but are intended to be added in the future.

The core starts execution at address 0x00000000.


Bus arbiter
===========

src/vhdl/arbiter

This is a basically a muxer for the output signals of the peripheral devices and generator for the device select signals. The topmost four bits of the bus address are used to determine the peripheral to be selected, which allows for up to 16 attached peripherals. Consequently, each device has 28 bits of address space available.



Synthesized RAM
===============

src/vhdl/ram

Four kilobytes of RAM, synthesized from FPGA block RAM (should be device-independent) and containing a test program. Eventually this should contain a simple bootloader that loads programs into a "proper" RAM device (e.g., the SDRAM contained on DE0-Nano board) and then jumps into the respective memory region.



VGA output
==========

src/vhdl/vga

This component generates a 640x480@60 Hz VGA signal with a 40x30 text mode. Eight colors (one bit per color channel) are supported.

Three RAM blocks are utilized by the design:

 - a text RAM, storing the character codes to be displayed
 - a color RAM, with a fore- and background-color coded in one byte (_RGB_RGB with _ denoting unused bits) per text character
 - a font RAM, containing a font for codepage 850, modifyable at runtime

These RAMs are synthesized from FPGA block RAM resources and thus should be device-independent.


Serial I/O
==========

src/vhdl/serial

A simple two-wire (TX and RX) serial interface that can be interfaced to, e.g., by means of a 3.3 Volt USB-serial cable. The interface is by default configured for 9600 Baud connections and features status registers to denote if fresh data has arrived and whether the device is ready to transmit data.


LED output
==========

src/vhdl/leds

The DE0-Nano board features eight LEDs, which can be controlled by the CPU by means of store instructions. The value currenty displayed can be read back.

