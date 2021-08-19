// Success

void main(){  // Testing 32 bit kernel
    
    char *buffer = (char*)0xb8000; // video memory
    
	for(int a=0; a<(80*25); a++, buffer++){
   	     *buffer = 0x0c; buffer++;
	     *buffer = 0x0a;
    }    	
    asm("hlt");
}
