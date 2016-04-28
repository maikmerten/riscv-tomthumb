void main() {
	int* addr1 =(int*) 0x2000;
	int* addr2 =(int*) 0x2004;
	int a = *addr1;
	int b = *addr2;
	int c = a*b;

	*addr1 = c;


}
