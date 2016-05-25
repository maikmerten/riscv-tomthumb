void main() {
	volatile char* serial_base = (char*) 0x20000000;

	while(1) {
		// wait for data to arrive on serial interface
		char ready = 0;
		while(!ready) {
			ready = *(serial_base + 1);
		}

		// read data from serial interface
		char val = *serial_base;

		// wait until serial interface is ready to transmit data
		ready = 0;
		while(!ready) {
			ready = *(serial_base + 2);
		}

		// transmit received data (echo)
		*serial_base = val;
	}
}
