[BITS 16]
[ORG 0x7c00]

  mov [BOOT_DRIVE], dl        ; bios store boot drive in dl
  
  mov   bp,  08000h           ; stack
  mov   sp,  bp
    
  
  push 0x8000                 ; kernel loading address
  pop  es


 ; loading disk
  mov  al,  2                ; number of sector we are reading 2 sector means 1kb
  mov  cl,  2
  mov  bx,  0x00              ; es:bx position to load
  mov  dl,  [BOOT_DRIVE]
  call disk_read
      
;_____________________________________________________ 
checkA20Line:
    push es
 
    xor  ax, ax               ; ax = 0
    mov  es, ax
	mov  byte[es:0500],  0x00
	
	not  ax
	mov  es, ax
	mov  byte[es:0510],  0xFF
	
	xor  ax, ax
	mov  es, ax 
	cmp  byte[es:0500],  0xff
    je  _checkA20Line_exit
    
	cmp  byte[A20CON], 0
	je  _byDefault
	
	cmp  byte[A20CON], 1
    je  _byBios	
	
	cmp  byte[A20CON], 2
	je  _byKeyboard
	
	cmp  byte[A20CON], 3
	je  _byFastgate
	
   _byFastgate:
    mov  si,  A20FASTGATE
	call print
	jmp _A20End
	
   _byKeyboard:
    mov  si,  A20BYKEYBOARD
	call print
	jmp _A20End
   
   _byBios:
    mov  si,  A20BYBIOS
	call print
	jmp _A20End
	
   _byDefault:
	mov  si,  A20ALREADY
	call print	
	jmp _A20End
	
   _checkA20Line_exit:   
	inc  byte[A20CON]
	
	cmp  byte[A20CON], 1
	je   EnableA20ByBIOS

    cmp  byte[A20CON], 2
	je   EnableA20ByKEYBOARD
	
	cmp  byte[A20CON], 3
	je   EnableA20FastGate
	
	cmp  byte[A20CON], 4
	je  _A20Fail
	
	jmp  checkA20Line
 
   _A20Fail:
    mov  si,  A20FAIL
	call print
   _A20End:
	
	pop  es
;_____________________________________________________
 
   
 

    mov  si,  PM
	call print
 
    mov   ah,  0
    int   0x16   ; wait for keypress
 
    cmp   al,  0x0d    ; ENTER for shutdown else switch_to_pm
    je    shutdown

setPixelMode:
    xor ax,  ax       ; necessary because remain some junk in al 
    mov ax,  0x13     ;  320x200 pixel mode
    int 0x10
	jmp  switch_to_pm
    
   
shutdown:
  mov ax, 0x1000
  mov ax, ss
  mov sp, 0xf000
  mov ax, 0x5307
  mov bx, 0x0001
  mov cx, 0x0003
  int 0x15
 
  ret  ;if interrupt doesnt work
	
    jmp  $

 

%include "include/A20.asm"
%include "include/print.asm"
%include "include/disk.asm"
%include "include/switch_to_pm.asm"
;%include "include/shutdown.asm"      ; already defined above

;DATA HERE_______________________________________________________________________
 
 BOOT_DRIVE    db 0
 
 A20CON        db 0
 A20FAIL       db "A20 fail", 0
 A20ALREADY    db "A20 dflt", 0
 A20BYBIOS     db "A20 BIOS", 0
 A20BYKEYBOARD db "A20 KEYB", 0
 A20FASTGATE   db "A20 FastGate"
 PM            db 0ah,"Enter for 32 bin kernel, any key to shutdown", 0
 
 %include "include/gdt.asm"   
 
;DATA END__________________________________________________________________
times 510-($-$$) db 0
dw 0xaa55

load_here:      ; load here is the location where kernel was initially store as a raw binary image the 
                ; after that it was loaded in 0x8000  (main memory address)

 %include "kernel.asm"