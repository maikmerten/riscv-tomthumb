.text
main:
	li t1,0x10000000 # address of LED output
	li t0,0x00000000 # init counter at zero
loop:
	
	addi t0,t0,1 	# increase counter
	srli t2,t0,16	# shift 16 positions right
	sb t2,0(t1)	# display lowest 8 bits on LED output
	j loop

.size	main, .-main

