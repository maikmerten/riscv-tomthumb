.text
main:
	or t0,x0,x0
	sw t0,512(x0)
	addi t1,x0,1
	li t2, 0x10000000 # address of LED output
	li t3, 0x30000000 # address of VGA text memory
loop:
	lw t0,512(x0)
	add t0,t0,t1
	sw t0,512(x0)
	sw t0, 80(t3) # write to VGA (four chars)
	sh t0,120(t3) # write to VGA (two chars)
	sb t0,160(t3) # write to VGA (one char)
	srli t0,t0,16 # shift to second most significant byte
	sw t0,0(t2) # blinky LEDs

	li t0,2
loop2:
	sub t0,t0,t1
	bge t0,x0,loop2

	j loop

.size	main, .-main
