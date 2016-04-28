.text
main:
	li t1,0x10000000
	li t0,0xffffffff
	sw t0,0(t1)
loop:
	j loop

.size	main, .-main

