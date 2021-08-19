
 ; This is the begining of the 32 bit KERNEL
 
 ; Don't change the label because it is defind in the switch_to_pm section

[BITS 32]
; [ORG 0x8000] 

 
 
   mov  eax,        0xa0000
   mov  ebx,        0    ; counter
   
  _done2: 
   cmp  ebx,        64000
   je   _done1
   
   mov  byte[eax],  0x0f
  
   inc  eax
   inc  ebx             ; incrementing counter
   
   jmp  _done2
   
   _done1:
   
   jmp  $           ; Hang.
   hlt
   

times 512 db 0