
 ; al = number of sectors to read
 ; cl = sector number to read form 
 ; bx = load in loaction  | in es:bx
 ; dl = drive number | 0x80 is the default
disk_read:

	; load disk sector into memory

	mov ah, 0x02                    ; load second stage to memory / function number for read
	mov ch, 0                       ; cylinder number
	mov dh, 0                       ; head number
	int 0x13                        ; disk I/O interrupt
    
	ret