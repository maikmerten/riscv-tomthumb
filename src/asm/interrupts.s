.macro rti
custom0 0,0,0,0
.endm


.text
	j main

.= 0x10
isr: 	li t1,0x10000000
	li t0,0x2
	sw t0,0(t1)
	rti

main:
	li t1,0x10000000
	li t0,0x1
	sw t0,0(t1)
	j main

.size	main, .-main

