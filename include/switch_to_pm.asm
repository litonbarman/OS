   [BITS 16]   
 switch_to_pm:
   cli
   lgdt  [gdt_descriptor]
   
   mov   eax,  cr0
   or    eax,  0x1
   mov   cr0,  eax
   jmp   CODE_SEG:init_pm
   
   
   [BITS 32]
 init_pm:
   mov  ax,   DATA_SEG     ; data segment
   mov  ds,   ax
   mov  ss,   ax
   mov  es,   ax
   mov  fs,   ax
   mov  gs,   ax
   
   mov  ebp,  0x9000      ; new stack
   mov  esp,  ebp
   
   call 0x8000          ; calling a first 32 bit function 
