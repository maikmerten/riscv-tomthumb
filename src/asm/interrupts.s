.macro rti
custom0 0,0,0,0
.endm


.text
	j main

# interrupt service routine at 0x10
.= 0x10
isr: 	li t1,0x10000000
	li t5,0x2
	sb t5,0(t1)
	rti

# we should only end up here if rti fails
fail:
	li t5,0x4
	sb t5,0(t1)
	j fail

# main program: flicker one board LED
main:
	li t1,0x10000000
	li t0,0x1
	sb t0,0(t1)

	li t2,99999
loop1:
	addi t2,t2,-1
	bne t2,zero,loop1



	li t0,0
	sb t0,0(t1)

	li t2,99999
loop2:
	addi t2,t2,-1
	bne t2,zero,loop2

	j main

.size	main, .-main

