;--------------------------------------------------------------------------------------------------------------;
;mbr.asm - Master Boot Record Final									       ;
;Rewritten by pANZERNOOb 										       ;
;from "Standard MBR" code - http://thestarman.pcministry.com/asm/mbr/STDMBR.htm				       ;
;and Windows 7 MBR code   - http://thestarman.pcministry.com/asm/mbr/W7MBR.htm				       ;
;You are free to use and modify this code as long as you give credit to its authors			       ;
;I am not responsible for the use or missuse of this code						       ;
;Assembled with NASM: nasm mbr.asm -f bin -o mbr.bin							       ;
;--------------------------------------------------------------------------------------------------------------;
org 0x7C00
bits 16

;--------------------------------------------------------------------------------------------------------------;
;Copy MBR from 0000:7C00 to 0000:0600									       ;
;Code Starts @ 0000:7C00										       ;
;--------------------------------------------------------------------------------------------------------------;
start:
	cli				;Clear interrupts
	xor  ax,ax			;Zero out AX
	mov  ss,ax			;Clear Stack Segment
	mov  sp,0x7C00			;Set stack @ 0000:7C00
	mov  si,sp			;Point SI to start of MBR
	push ax				;Zero out ES and DS
	pop  es			
	push ax
	pop  ds
	sti				;Set Interrupts 

	cld				;Don't forget this
	mov di,0x0600			;Point DI to 0600, where the MBR will be copied to
	mov cx,0x0200			;Copy Whole 512 bytes
	rep movsb			;Copy MBR to 0000:0600
	
	push cs				;Segment:0000
	push WORD 0x061D		;Offset:061D
	retf		   		;Resume Execution 
;--------------------------------------------------------------------------------------------------------------;

;--------------------------------------------------------------------------------------------------------------;
;The following code has been relocated to 0000:061D							       ;
;Go through partition table and find an active entry	                                                       ;						
;--------------------------------------------------------------------------------------------------------------;
	mov cx,0x0004  			;Check four Partitions
	mov bp,0x07BE  			;Point BP to Start of Part Table
	
Check_Parts:
	cmp BYTE [bp+0x00],0x80		;Is partition active?
	je  Check_Ext			;Yep, Check for INT13 Extensions
	cmp BYTE [bp+0x00],0x00 	;Is flag Valid?
	jnz Invalid_Table		;Nope, "Invalid partition table!"
	add bp,0x10			;Add 16 Bytes
	loop Check_Parts		;Next entry

	int 0x18			;No Active Parts, INT 18h - ROM BASIC/ERROR MSG
;--------------------------------------------------------------------------------------------------------------;

;--------------------------------------------------------------------------------------------------------------;
;Check For INT 13h Extensions										       ;
;--------------------------------------------------------------------------------------------------------------;
Check_Ext:
	mov BYTE [bp+0x00],dl		;Overwrite Status flag with Drive Number
	pusha				;Save 16-bit registers	

	mov ah,0x41			;INT 13h AH=41h: Check Extensions Present	
	mov bx,0xAA55			;Must be AA55
	int 0x13			;Check extensions
	jc  No_Ext			;Carry flag set, No extensions
	cmp bx,0x55AA			;Is BX 55AA
	jnz No_Ext			;Nope, No extensions
;--------------------------------------------------------------------------------------------------------------;

;--------------------------------------------------------------------------------------------------------------;	
;Read VBR to 0000:7C00 using INT13h Extensions								       ;
;--------------------------------------------------------------------------------------------------------------;
	mov di,0x0005			;Attempt to read drive 5 times
Ext_Read:
	push di				;Stash Read count
	xor  eax,eax			;Zero out EAX
					;Push DAP to the stack
					;DAP : Disk Address Packet
					;00h BYTE  : Size of DAP(10h, 16 bytes)
					;01h BYTE  : Reserved
					;02h WORD  : Number of Sectors to read
					;04h DWORD : segment:offset of where sectors are to be read to
					;08h QWORD : LBA of where to read From
	push DWORD eax			;MSD of Start LBA:Zero
	push DWORD [bp+0x08] 		;LSD of Start LBA:LBA of VBR
	push WORD cs			;Segment:0000
	push WORD 0x7C00		;Offset:7C00 
	push WORD 0x0001		;Sectors to read:1
	push WORD 0x0010		;Reserved/Size: 16 bytes
	
	mov ah,0x42	     		;INT 13h AH=42h: Extended Read Sectors From Drive
	mov dl,[bp+0x00]     		;DL = Drive Number
	mov si,sp	    		;Point SI to the beginning of DAP
	int 0x13	    		;Read VBR into Memory @ 0000:7C00
	
	lahf		     		;Save Flags
	add sp,0x10	     		;Reset Stack pointer to it's position before we pushed the DAP
	pop di				;Restore Read Count
	sahf		     		;Restore Flags
	jnc Verify_VBR			;Carry not set? Continue to load VBR
	
	dec di				;Decrease Read Count
	or di,di			;Is DI zero
	jz Error_Load			;Yes, "Error loading operating system!"
	xor ax,ax			;INT 13h AH=00h: Reset Disk Drive
	int 0x13			;Reset Disk
	jmp Ext_Read			;Try Again
;--------------------------------------------------------------------------------------------------------------;

;--------------------------------------------------------------------------------------------------------------;	
;Load VBR to 0000:7C00 without INT13h Extensions							       ;
;--------------------------------------------------------------------------------------------------------------;
No_Ext:
	mov di,0x0005			;Attempt to read drive 5 times
Read_Disk:
	push di				;Stash Read count
	mov ax,0x0201 	     		;AH = 02h Read Sector AL = 01h One sector
	mov bx,0x7C00	     		;Read to 0000:7C00
	mov dl,[bp+0x00]     		;DL = Drive number
	mov dh,[bp+0x01]     		;DH = Head Number
	mov cl,[bp+0x02]		;CL = Bits 0-5 make up Sector Number 
	mov ch,[bp+0x03]		;CH = Along with bits 6-7 of CL makes up the Cylinder
	int 0x13			;INT13, Function 02h: READ SECTORS
	
	pop di				;Restore Read Count
	jnc Verify_VBR			;Carry flag clear? Continue to load VBR
	dec di				;Decrease Read Count
	or di,di			;Is DI zero
	jz Error_Load			;Yes, "Error loading operating system!"
	xor ax,ax			;INT 13h AH=00h: Reset Disk Drive
	int 0x13			;Reset Disk
	jmp Read_Disk			;Try Again
;--------------------------------------------------------------------------------------------------------------;

;--------------------------------------------------------------------------------------------------------------;
;Verify that VBR is valid and Return to VBR code @ 0000:7C00			                               ;			 
;--------------------------------------------------------------------------------------------------------------;
Verify_VBR:
	mov si,0x7DFE			;Point to VBR_Sig  
	cmp WORD [si],0xAA55		;Is VBR_Sig AA55
	jne Missing_OS			;Nope, "Missing operating system!"
	
	popa				;Restore 16-bit registers 
	mov dl,[bp+0x00]		;Restore Drive Number to DL
	stc				;Indicates that MBR is present	
	push cs				;Segment:0000
	push 0x7C00			;Offset:7C00
	retf				;Jump to the Volume Boot Record
;--------------------------------------------------------------------------------------------------------------;

;--------------------------------------------------------------------------------------------------------------;
;Error Handling Routine											       ;
;--------------------------------------------------------------------------------------------------------------;
Invalid_Table:
	mov si,0x0765			;"Invalid partition table!"
	jmp Print_Error
Error_Load:
	mov si,0x077E			;"Error loading operating system!"
	jmp Print_Error	
Missing_OS:
	mov si,0x79E			;"Missing operating system!"
Print_Error:
	lodsb				;Load [SI] into AL and increment SI
	or al,al			;Zero Byte?
	jz Freeze			;Done? Freeze computer
	mov ah,0x0E			;AH=Print character to screen		
	mov bx,0x0007		
	int 0x10		
	jmp Print_Error
Freeze:
	jmp $
;--------------------------------------------------------------------------------------------------------------;

times 357 - ($ - $$) 	db 0x00	;Fill Remaining Code section with Zeros

;--------------------------------------------------------------------------------------------------------------;
;Error Messages @ 0000:0765										       ;
;--------------------------------------------------------------------------------------------------------------;
MSG_Invalid_Table 	db "Invalid partition table!",0x00		
MSG_Error_Load	  	db "Error loading operating system!",0x00	
MSG_Missing_OS	  	db "Missing operating system!",0x00		
;--------------------------------------------------------------------------------------------------------------;
;End of code
;--------------------------------------------------------------------------------------------------------------;
Disk_Sig dd 0x00000000
Reserved dw 0x0000
;--------------------------------------------------------------------------------------------------------------;

;--------------------------------------------------------------------------------------------------------------;
;Partition table @ 0000:07BE										       ;
;--------------------------------------------------------------------------------------------------------------;
PT1_Status		db 0x80		;Drive number/Bootable flag
PT1_First_Head  	db 0x01		;First Head
PT1_First_Sector	db 0x01		;Bits 0-5:First Sector|Bits 6-7 High bits of First Cylinder
PT1_First_Cylinder	db 0x00		;Bits 0-7 Low bits of First Cylinder
PT1_Part_Type		db 0x0C		;Partition Type
PT1_Last_Head	  	db 0xFF		;Last Head 
PT1_Last_Sector		db 0xFF		;Bits 0-5:Last Sector|Bits 6-7 High bits of Last Cylinder
PT1_Last_Cylinder	db 0xFF		;Bits 0-7 Low bits of Last Cylinder
PT1_First_LBA		dd 0x0000003F	;Starting LBA of Partition
PT1_Total_Sectors	dd 0x0003DC00	;Total Sectors in Partition

PT2_Status		db 0x00
PT2_First_Head  	db 0x00
PT2_First_Sector	db 0x00
PT2_First_Cylinder	db 0x00
PT2_Part_Type		db 0x00
PT2_Last_Head	  	db 0x00
PT2_Last_Sector		db 0x00
PT2_Last_Cylinder	db 0x00
PT2_First_LBA		dd 0x00000000
PT2_Total_Sectors	dd 0x00000000

PT3_Status		db 0x00
PT3_First_Head  	db 0x00
PT3_First_Sector	db 0x00
PT3_First_Cylinder	db 0x00
PT3_Part_Type		db 0x00
PT3_Last_Head	  	db 0x00
PT3_Last_Sector		db 0x00
PT3_Last_Cylinder	db 0x00
PT3_First_LBA		dd 0x00000000
PT3_Total_Sectors	dd 0x00000000

PT4_Status		db 0x00
PT4_First_Head  	db 0x00
PT4_First_Sector	db 0x00
PT4_First_Cylinder	db 0x00
PT4_Part_Type		db 0x00
PT4_Last_Head	  	db 0x00
PT4_Last_Sector		db 0x00
PT4_Last_Cylinder	db 0x00
PT4_First_LBA		dd 0x00000000
PT4_Total_Sectors	dd 0x00000000
;--------------------------------------------------------------------------------------------------------------;
MBR_Sig dw 0xAA55			;Indicates a Bootable Sector