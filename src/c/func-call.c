
char readSerial();
void writeSerial(char val);

void main() {
	char val = 0;
	while(1) {
		val = readSerial();
		writeSerial(val);
	}
}

char readSerial() {
	volatile char* serial_base = (char*) 0x20000000;

	// wait for data to arrive on serial interface
	char ready = 0;
	while(!ready) {
		ready = *(serial_base + 1);
	}

	// read data from serial interface
	char val = *serial_base;
	return val;
}

void writeSerial(char val) {
	volatile char* serial_base = (char*) 0x20000000;

	// wait until serial interface is ready to transmit data
	char ready = 0;
	while(!ready) {
		ready = *(serial_base + 2);
	}

	// transmit received data (echo)
	*serial_base = val;
}
