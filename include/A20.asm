; obviously since we are using here 16 bit register
; so we need to call the function enableA20Line function
; before jumping into protected mode
; it return through ax
; if ax = 0 then its false

;_checkA20Line:
;    push es
 
;    xor  ax,   ax               ; ax = 0
;    mov  es,   ax
;	mov  byte[es:0500],  0x00
	
;	not  ax
;	mov  es,   ax
;	mov  byte[es:0510],  0xFF
	
;	xor  ax,   ax
;	mov  es,   ax 
;	cmp  byte[es:0500],  0xff
;    je  _checkA20Line_exit_
    
;	mov  si,   A20YES
;	call print	
;	jmp _A20End_
	
;  _checkA20Line_exit_:
 
;    mov  si,   A20NO
;	call print
;   _A20End_:
	
;	pop  es
;	ret

EnableA20ByBIOS:
    mov  ax,   0x2501
	int  0x15
	ret
	
	
EnableA20FastGate:    ; our last option
    in   al,   0x92
    or   al,   2
    out  0x92, al
    ret
	
EnableA20ByKEYBOARD:
    cli
	call    Wait_8042_command
    mov     al,0xAD
    out     0x64,al

    call    Wait_8042_command
    mov     al,0xD0
    out     0x64,al

    call    Wait_8042_data
    in      al,0x60
    push    eax
	
    call    Wait_8042_command
    mov     al,0xD1
    out     0x64,al            

    call    Wait_8042_command
    pop     eax
    or      al,2
    out     0x60,al

    call    Wait_8042_command
    mov     al,0xAE
    out     0x64,al

    call    Wait_8042_command

    sti 
    ret	

Wait_8042_command:
    in      al,0x64
    test    al,2
    jnz     Wait_8042_command
    ret
  
Wait_8042_data:
    in      al,0x64
    test    al,1
    jz      Wait_8042_data
    ret