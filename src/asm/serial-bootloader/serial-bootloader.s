#define LED	0x10000000
#define SERIAL	0x20000000
#define R_TMP	s1
#define R_ADDR	s2
#define R_CHK	s3

.text
j main


.=196

##########
read_serial:
##########
	li t0,SERIAL
read_byte_wait:
	lb t1,1(t0) 		# load serial status register
	beqz t1,read_byte_wait	# loop until ready to read
	lbu a0,0(t0)		# read byte without sign extension
	xor R_CHK,R_CHK,a0	# xor check sum
	ret

##########
write_serial:
##########
	li t0,SERIAL
write_byte_wait:
	lb t1,2(t0)		# load status register
	beqz t1,write_byte_wait	# loop until ready to write
	sb a0,0(t0)		# write byte to serial output
	ret

##########
write_led:
##########
	li t0,LED
	sb a0,0(t0)
	ret

##########
read_address:
##########
	addi sp,sp,-4
	sw ra,0(sp)

	li R_ADDR,0x0
	li R_TMP,0x4
read_address_loop:
	jal read_serial			# read byte from serial
	jal write_led
	slli R_ADDR,R_ADDR,8		# shift address register one byte left
	or R_ADDR,R_ADDR,a0		# fill lowest eight bits with read byte
	addi R_TMP,R_TMP,-1		# decrement loop counter
	bnez R_TMP,read_address_loop	# loop until counter is zero

	mv a0,R_CHK
	jal write_serial		# transmit checksum

	lw ra,0(sp)
	addi sp,sp,4
	ret

##########
read_mem:
##########
	addi sp,sp,-4
	sw ra,0(sp)

	mv a0,R_CHK
	jal write_serial		# transmit checksum

	lbu a0,0(R_ADDR)		# read byte from current address
	jal write_led
	jal write_serial		# write byte to serial port
	addi R_ADDR,R_ADDR,1		# increment address

	lw ra,0(sp)
	addi sp,sp,4
	ret

##########
write_mem:
##########
	addi sp,sp,-4
	sw ra,0(sp)

	jal read_serial			# read byte from serial port
	jal write_led
	sb a0,0(R_ADDR)			# store byte to current address
	addi R_ADDR,R_ADDR,1		# increment address

	mv a0,R_CHK
	jal write_serial		# transmit checksum

	lw ra,0(sp)
	addi sp,sp,4
	ret

##########
call:
##########
	addi sp,sp,-4
	sw ra,0(sp)

	mv a0,R_CHK
	jal write_serial		# transmit checksum

	jalr R_ADDR

	lw ra,0(sp)
	addi sp,sp,4
	ret


##########
main:
##########

	# dump registers to fixed memory locations
	sw x1,16(zero)
	sw x2,20(zero)
	sw x3,24(zero)
	sw x4,28(zero)
	sw x5,32(zero)
	sw x6,36(zero)
	sw x7,40(zero)
	sw x8,44(zero)
	sw x9,48(zero)
	sw x10,52(zero)
	sw x11,56(zero)
	sw x12,60(zero)
	sw x13,64(zero)
	sw x14,68(zero)
	sw x15,72(zero)
	sw x16,76(zero)
	sw x17,80(zero)
	sw x18,84(zero)
	sw x19,88(zero)
	sw x20,92(zero)
	sw x21,96(zero)
	sw x22,100(zero)
	sw x23,104(zero)
	sw x24,108(zero)
	sw x25,112(zero)
	sw x26,116(zero)
	sw x27,120(zero)
	sw x28,124(zero)
	sw x29,128(zero)
	sw x30,132(zero)
	sw x31,136(zero)

	# initialize stack pointer to somewhere between the register dump and
	# the bootloader code
	li sp,196

main_read_cmd:
	# clear checksum
	add R_CHK,zero,zero

	jal read_serial
	jal write_led

	li t0,'A'		# check for "read address" command
	beq t0,a0,main_cmd_address

	li t0,'R'		# check for "read from address" command
	beq t0,a0,main_cmd_read

	li t0,'W'		# check for "write to address" command
	beq t0,a0,main_cmd_write

	li t0,'C'		# check for "call address" command
	beq t0,a0,main_cmd_call

	j main_read_cmd		# no command found, back to reading next command


main_cmd_address:
	jal read_address
	j main_read_cmd

main_cmd_read:
	jal read_mem
	j main_read_cmd

main_cmd_write:
	jal write_mem
	j main_read_cmd

main_cmd_call:
	jal call
	j main


.size	main, .-main

