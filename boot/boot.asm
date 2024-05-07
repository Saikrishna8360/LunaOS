[BITS 16]           ; 16-bit mode
[ORG 0x7c00]        ; Bootloader start address

start:
    xor ax, ax       ; Initialize segment registers to 0
    mov ds, ax
    mov es, ax  
    mov ss, ax
    mov sp, 0x7c00   ; stack pointer

TestDiskExtension:
    mov [DriveId], dl
    mov ah, 0x41
    mov bx, 0x55aa
    int 0x13
    jc NotSupport
    cmp bx, 0xaa55
    jne NotSupport

; Loads loader program into 0x7e00 and jumps to it
LoadLoader:
    mov si, ReadPacket       ; Setting up parameters for disk read
    mov word[si], 0x10      ; Number of sectors to read
    mov word[si+2], 5       ; Start sector
    mov word[si+4], 0x7e00  ; Destination offset
    mov word[si+6], 0       ; Destination Segment
    mov dword[si+8], 1      ; Number of sectors to read
    mov dword[si+0xc], 0    ; Absolute LBA (Logical Block Address) of the sector to read
    mov dl, [DriveId]
    mov ah, 0x42            ; BIOS interrupt for disk read
    int 0x13
    jc  ReadError

    mov dl, [DriveId]
    jmp 0x7e00 

ReadError:
NotSupport:
    mov ah, 0x13        ; Instructions to write message
    mov al, 1
    mov bx, 0xa
    xor dx, dx
    mov bp, Message
    mov cx, MessageLen 
    int 0x10

End:
    hlt    
    jmp End
    
DriveId:    db 0
Message:    db "Error in boot process"
MessageLen: equ $-Message
ReadPacket: times 16 db 0

times (0x1be - ($ - $$)) db 0

    db 80h
    db 0, 2, 0
    db 0f0h
    db 0ffh, 0ffh, 0ffh
    dd 1
    dd (20*16*63-1)
	
    times (16*3) db 0

    db 0x55
    db 0xaa

	
