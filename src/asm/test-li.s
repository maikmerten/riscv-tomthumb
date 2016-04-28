.text
main:
loop:
	li t0,0xFEFEBEEF
	sw t0,48(x0)
	j loop

.size	main, .-main

