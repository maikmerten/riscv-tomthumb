.section .text
 
.global _start
_start:

# set up stack pointer
li sp,2048

# call main function
jal ra,main

# back to start
j _start
