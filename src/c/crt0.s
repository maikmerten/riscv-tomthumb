.section .text
 
.global _start
_start:

# set up stack pointer
li sp,4096

# call main function
jal ra,main

# back to start
j _start
