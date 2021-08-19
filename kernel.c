
void main(){  // Testing 32 bit kernel
    char *buffer = (char*) 0xb8000; // video memory

   	for(int a=0; a<=(25*80); a++){
		*buffer = 0x0c;
	}
	
    asm("hlt");
}