.text
main:
	li t1,0x10000000 # led mem address
	li t2,0x20000000 # serial port
loop:

	# loop until serial data is available
wait_read:
	lb t5,1(t2) # load serial status for reading
	beq t5,x0,wait_read

	# we got data!
	lb t0,0(t2) # read serial data
	sb t0,0(t1) # push to leds

wait_write:
	lb t5,2(t2) # load serial status for writing
	beq t5,x0,wait_write

	sb t0,0(t2) # write back to serial port


	j loop

.size	main, .-main

