.text
main:
	li t1,0x10000000 # led mem address
loop:

	li x1,1
	li x2,0x00100000
wait:
	sub x2,x2,x1
	bne x2,x0,wait

	li t6,0x00000055 # 0101 0101
	sw t6,0(t1) # push to leds

	li x2,0x00100000
wait2:
	sub x2,x2,x1
	bne x2,x0,wait2
	
	li t5,0x000000FF
	xor t6,t6,t5 # invert blinky pattern
	sw t6,0(t1) # push to leds

	
	j loop

.size	main, .-main

