print:  ; argument in si
   pusha 
   mov   ah,  0x0e
   
  _repeat:
   lodsb
   cmp   al,  0
   je   _done
   int   010h
   jmp  _repeat
  _done:
   
   popa
   ret
   
   
clrscr:
   mov   ax,  0x0600      ; Fn 06 of int 10h,scroll window up,if al = 0 clrscr
   mov   cx,  0x0000      ; Clear window from 0,0
   mov   dx,  0x174f      ; to 23,79
   mov   bh,  0           ; fill with colour 0
   int   0x10             ; call bios interrupt 10h
   ret
   
setCursorPos:
   mov  ah,   0x02        ; this is the function number
   mov  bh,   0           ; page default to zero
   mov  dh,   0           ; row
   mov  dl,   0           ; column
   int  0x10
   ret