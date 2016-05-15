.text
main:
	li s1, 0x10000000 # address of LED output
	li s2, 0x30000000 # address of VGA text RAM
	li s3, 0x30000800 # address of VGA color RAM
	sw zero, 80(s2)

loop:
	lw t0, 80(s2) # retrieve value from VGA text RAM
	addi t0,t0,1  # increment value
	sw t0, 80(s2) # write to VGA (four chars)
	sh t0,120(s2) # write to VGA (two chars)
	sb t0,160(s2) # write to VGA (one char)

	# select color code
	srli t0,t0,16 # shift to second most significant byte
	sw t0,0(s1)   # show color code on LEDs

	lbu t0,0(s1)   # load color code from LED device (unsigned)
	lbu t1,0(s3)   # load first byte from color RAM (unsigned)
	beq t0,t1,loop # if the color matches, skip coloring

	# loop to apply fresh color value
	li t1,0       # set index to 0
	li t2,40      # set index bound to 40 (first row)
apply_color:
	add t3,t1,s3  # add index to color RAM base address
	sb t0,0(t3)   # store color value
	addi t0,t0,1  # increment color value for next char
	addi t1,t1,1  # increment index
	bne t1,t2,apply_color

	j loop

.size	main, .-main
