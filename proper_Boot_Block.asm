; Not completed yet

[ORG 0x7c00]
[BITS 16]
 
 jmp   _start_bootloader
 db    'Clown OS'                        ; strictly of 8 bytes
 
 bytesPerBlock  db  512
 blockPerAlloc  db                       ; don't know
 reservedBlock  db  2                    ; since using 2 sectors for full bootloader
 noFileAllocTa  db  2
 noOfRootDirec  db  1
 totalNoBlocks  db  65535
 mediaDescript  db                       ; don't know
 blockPerFAtab  db  1
 noOfBperTrack  db                       ; don't know
 noOfHeadsinDr  db  0                    ; 0 for pandrive
 noOfHiddenBlo  db  2
 noOfTotalBloc  db
 
 

_start_bootloader: