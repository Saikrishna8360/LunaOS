[BITS 16]
[ORG 0x7e00]

start:
    mov [DriveId], dl

    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb NotSupport

    mov eax, 0x80000001
    cpuid
    test edx, (1<<29)
    jz NotSupport
    test edx, (1<<26)
    jz NotSupport

LoadKernel:
    mov si, ReadPacket
    mov word[si], 0x10
    mov word[si+2], 100     
    mov word[si+4], 0       
    mov word[si+6], 0x1000  
    mov dword[si+8], 6       ; Since first 6 sectors for boot and loader programs
    mov dword[si+0xc], 0
    mov dl,[DriveId]
    mov ah,0x42
    int 0x13
    jc  ReadError

GetMemInfoStart:            ; Get memory map information
    mov eax, 0xe820
    mov edx, 0x534d4150
    mov ecx, 20
    mov dword[0x9000], 0
    mov edi, 0x9008
    xor ebx, ebx
    int 0x15
    jc NotSupport

GetMemInfo:
    add edi, 20
    inc dword[0x9000]   
    test ebx, ebx
    jz GetMemDone

    mov eax, 0xe820
    mov edx, 0x534d4150
    mov ecx, 20
    int 0x15
    jnc GetMemInfo


GetMemDone:
TestA20:        ; routine to check A20 line
    mov ax,0xffff
    mov es,ax
    mov word[ds:0x7c00], 0xa200
    cmp word[es:0x7c10], 0xa200
    jne SetA20LineDone
    mov word[0x7c00], 0xb200
    cmp word[es:0x7c10], 0xb200
    je End
    
SetA20LineDone:
    xor ax, ax
    mov es, ax

SetVideoMode:       ; routine to set video mode - text mode
    mov ax, 3
    int 0x10
    
    cli             ; disable interrupts
    lgdt [Gdt32Ptr] ; load global descriptor table
    lidt [Idt32Ptr] ; load interrupt descriptor table

    mov eax, cr0
    or eax, 1
    mov cr0, eax    ; cr0  - control register to toggle protected mode

    jmp 8:PMEntry   ; 8 - index selector


ReadError:
NotSupport:
End:
    hlt    
    jmp End

[BITS 32]
PMEntry:
    mov ax, 0x10  ; data segment - 3rd entry which is 16 ( each entry 8 bytes)
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x7c00 ; stack pointer to 0


; Long mode - 64 bit mode
; OS Kernel and applications run in 64-bit mode
; No segmentation in 64-bit mode so paging
; IDT entry 16 bytes

; 48 bit virtual Address space

    cld                  ; clear direction flag
    mov edi, 0x70000
    xor eax, eax
    mov ecx, 0x10000/4
    rep stosd
    
    mov dword[0x70000], 0x71003
    mov dword[0x71000], 10000011b

    ; mov eax, (0xffff800000000000>>39)
    ; and eax, 0x1ff
    ; mov dword[0x70000+eax*8], 0x72003
    ; mov dword[0x72000], 10000011b

    lgdt [Gdt64Ptr]

    ; PAE allows the system to address more than 4 GB of physical memory on x86 processors.
    mov eax, cr4         ; cr4 - bit 5 - physical address extension 
    or eax, (1<<5)       ; set bit 5
    mov cr4, eax

    mov eax, 0x70000      ; value represents the physical address of the page directory base for paging. (sets to cr3)
    mov cr3, eax

    mov ecx, 0xc0000080     ; value represents the model-specific register (MSR) that controls various processor features.
    rdmsr                   ; read msr to eax
    or eax, (1<<8)          ; set 8th bit - enable long mode - (LME) flag in the MSR
    wrmsr                   ; write msr (in ecx register)

    mov eax, cr0            ; enable paging by setting bit 31 in cr0 register, allowing the processor to use virtual memory
    or eax, (1<<31)
    mov cr0, eax

    jmp 8:LMEntry           ; code segement descriptor is in 2nd entry

PEnd:
    hlt    
    jmp End

; Long Mode entry
[BITS 64]
LMEntry:
    mov rsp, 0x7c00         ; initialize stack pointer


    cld ; clears the direction flag, ensures that string operations - move data from lower to higher memory addresses
    mov rdi, 0x200000   ; destination address
    mov rsi, 0x10000    ; source address
    mov rcx, 51200/8    ; number of quadwords to copy - 100 sectors each 512 bytes
    rep movsq
    ; repeats the movsq (move quadword (8 bytes) from rsi to rdi) operation rcx times, effectively copying 51200 bytes from the source address (0x10000) to the destination address (0x200000)

    jmp 0x200000
    ; mov rax,0xffff800000200000
    ; jmp rax
    
LEnd:
    hlt
    jmp LEnd
    
   

DriveId:    db 0
Message:    db "Text Mode set"
MessageLen: equ $-Message
ReadPacket: times 16 db 0

Gdt32:
    dq 0

Code32:
    dw 0xffff
    dw 0
    db 0
    db 0x9a         ;  segment attributes            P DPL S TYPE  - 1 00 1 1010
    db 0xcf         ;  segment size + attributes     G D 0 A LIMIT - 1 1 0 0 1111
    db 0

Data32:
    dw 0xffff
    dw 0
    db 0
    db 0x92 
    db 0xcf     
    db 0

Gdt32Len: equ $-Gdt32

Gdt32Ptr: dw Gdt32Len-1
          dd Gdt32

Idt32Ptr: dw 0
          dd 0


Gdt64:
    dq 0
    dq 0x0020980000000000   ; code segment descriptor entry - D L   P DPL 1 1 C - 0 1   1 00 1 1 0
; No data segment required in GDT for ring 0

Gdt64Len: equ $-Gdt64

Gdt64Ptr: dw Gdt64Len-1
          dd Gdt64
