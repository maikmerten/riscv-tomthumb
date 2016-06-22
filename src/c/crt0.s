.macro rti
custom0 0,0,0,0
.endm

.macro rtt
custom0 0,0,0,8
.endm

.macro gtret rd
custom0 \rd,0,0,9
.endm

.section .text
 
.global _start
_start:
# reset vector at 0x0
.=0x0
j _init

# interrupt vector at 0x8
.=0x8
# for now, just return from interrupt
rti

# trap handler at 0x10
.=0x10
# don't handle anything, just return from trap
rtt

_init:
# set up stack pointer
li sp,4096

# call main function
jal ra,main

# back to start
j _start
