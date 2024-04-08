[BITS 16]
[ORG 0x7e00]

start:
    mov [DriveId],dl

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
    mov dl, [DriveId]
    mov ah, 0x42
    int 0x13
    jc  ReadError

LoadUser:
    mov si, ReadPacket
    mov word[si], 0x10
    mov word[si+2], 10
    mov word[si+4], 0
    mov word[si+6], 0x2000
    mov dword[si+8], 106       ; Since first 106 sectors for boot, loader and kernel programs
    mov dword[si+0xc], 0
    mov dl, [DriveId]
    mov ah, 0x42
    int 0x13
    jc  ReadError

GetMemInfoStart:    ; Get memory map information
    mov eax, 0xe820
    mov edx, 0x534d4150
    mov ecx, 20
    mov dword[0x9000], 0        ; store count of structures of memory map info 
    mov edi, 0x9008             ; structures are stored from 0x9008
    xor ebx, ebx
    int 0x15
    jc NotSupport

GetMemInfo:
    add edi, 20                 ; get next structure
    inc dword[0x9000]           ; increase count
    test ebx, ebx               ; test ebx, if ebx is 0, it means that we reach the end and we jump to getMemDone.
    jz GetMemDone

    mov eax, 0xe820
    mov edx, 0x534d4150
    mov ecx, 20
    int 0x15                    ; If carry flag is not set after executing int instruction, we will jump to get mem info    
    jnc GetMemInfo


GetMemDone:
TestA20:            ; routine to check A20 line
    mov ax, 0xffff
    mov es, ax
    mov word[ds:0x7c00], 0xa200
    cmp word[es:0x7c10], 0xa200
    jne SetA20LineDone
    mov word[0x7c00], 0xb200
    cmp word[es:0x7c10], 0xb200
    je End
    

SetA20LineDone:  
    xor ax, ax
    mov es, ax

SetVideoMode:   ; routine to set video mode - text mode
    mov ax, 3
    int 0x10
    
    cli             ; disable interrupts
    lgdt [Gdt32Ptr] ; load global descriptor table
    lidt [Idt32Ptr] ; load interrupt descriptor table

    mov eax, cr0
    or eax, 1
    mov cr0, eax    ; cr0  - control register - bit 0 to toggle protected mode

    jmp 8:PMEntry   ; 8 - index selector for code segment which is 2nd entry so 8
    ; code segement descriptor is in 2nd entry
    ; 8 - 00001(Index)   0 (TI) 00 (RPL)
    ; 15                 3   2   1     0      
;    Selector Index     RPL     TI (means to use GDT)

ReadError:
NotSupport:
End:
    hlt
    jmp End


[BITS 32]
PMEntry:        ; segment registers hold index of entry in GDT, so set to the index of data segment entry
    mov ax, 0x10 ; data segment - 3rd entry which is 16 ( each entry 8 bytes)
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x7c00  ; stack pointer to 0x7c00


; Long mode - 64 bit mode
; OS Kernel and applications run in 64-bit mode
; No segmentation in 64-bit mode so paging
; IDT entry 16 bytes

; 48 bit virtual Address space

    cld                  ; clear direction flag
    ; The code here is for setting up paging. First off, we zero the 10000 bytes of memory region starting from 70000.
    mov edi, 0x70000
    xor eax, eax
    mov ecx, 0x10000/4
    rep stosd
    
    ; Each entry in the page map level 4 table represent 512g and we only implement the low 1g, so we set up the first entry of the table.
    
    ; store next table address (page directory pointer table) as first entry in main page table, so the address is 71000 (Each table takes up 4k space, since the table include 512 entries (each entry 8 bytes - 64 bits)) - attributes - 011 -> 3 (only accessed by kernel)

    ; setup physical page table entries for virtual address 0 for kernel for 1 GB page size
    mov dword[0x70000], 0x71003       
    mov dword[0x71000], 10000011b       ; 011 -> 3 (only kernel mode access) and 7th bit set to 1 to represent 1 GB page translation

    ; remap kernel from 200000 to 0xffff800000200000
    ; we map the virtual address to the same 1g physical page. So the two translations we set up will eventually point to the same physical page where the kernel is stored

    mov eax, (0xffff800000000000>>39)   ; index is from 39th bit
    and eax, 0x1ff                      ; get index using and operation
    mov dword[0x70000+eax*8], 0x72003   ; load the next page level table address (0x72000, attributes - 3) to page table entry at index (each entry 8 bytes) 
    mov dword[0x72000], 10000011b       ; same as kernel address set in physical page    





    lgdt [Gdt64Ptr]

; PAE allows the system to address more than 4 GB of physical memory on x86 processors.
    mov eax, cr4         ; cr4 - bit 5 - physical address extension 
    or eax, (1<<5)       ; set bit 5
    mov cr4, eax

    mov eax, 0x70000      
    mov cr3, eax            ; The value of cr3 is 70000. So the address of page map level 4 table is 70000.



    mov ecx, 0xc0000080     ; index value represents the model-specific register (MSR) that controls various processor features.
    rdmsr                   ; read msr to eax
    or eax, (1<<8)          ; set 8th bit - enable long mode - (LME) flag in the MSR
    wrmsr                   ; write msr (in ecx register)

    mov eax, cr0             ; enable paging by setting bit 31 in cr0 register, allowing the processor to use virtual memory
    or eax, (1<<31)
    mov cr0, eax

    jmp 8:LMEntry           
    ; specify the segment selector 8, since each entry is 8 bytes and the code segment selector is the second entry and then the offset long mode entry (LMEntry)
PEnd:
    hlt
    jmp PEnd

[BITS 64]
LMEntry:
    mov rsp, 0x7c00          ; initialize stack pointer

    cld                      ; clears the direction flag, ensures that string operations - move data from lower to higher memory addresses
    mov rdi, 0x200000        
    mov rsi, 0x10000         ; Destination address
    mov rcx, 51200/8         ; number of quadwords to copy - 100 sectors each 512 bytes
    rep movsq                ; repeats the movsq (move quadword (8 bytes) from rsi to rdi) operation rcx times, effectively copying 51200 bytes from the source address (0x10000) to the destination address (0x200000)

    mov rax, 0xffff800000200000     ; load kernel address to rax and use rax to jump
    jmp rax
    
LEnd:
    hlt
    jmp LEnd
    
    

DriveId:    db 0
ReadPacket: times 16 db 0

Gdt32:
    dq 0
; First entry is empty. Each entry 8 bytes (64 bits)

Code32:
    dw 0xffff       ; Lower (2 bytes) 16 bits - segment size - maximum size so 0xffff
    dw 0            ; Next 24 bits - base address - set to 0 (Cade segment starts from 0)
    db 0
    db 0x9a         ; segment attributes            P DPL S TYPE  - 1 00 1 1010 (readable)
    db 0xcf         ; segment size + attributes     G D 0 A LIMIT - 1 1 0 0 1111
    db 0            ; remaining 8 bits set to zero 
; S - code/ segment descriptor - 1
; Type - Conforming/ non-confirming (1010 - non-confirming)
; DPL - privilege level - 0
; P - present bit

; LIMIT - upper 4 bits of segment size (set to maximum)
; A - available bit
; D - Default operand size - 1 -> 32 bit (else 16 bit)
; G - Granularity bit - if 1 -> size field scaled by 4kb


Data32:
    dw 0xffff
    dw 0
    db 0
    db 0x92        ; TYPE - 0010 (readable and writable)
    db 0xcf
    db 0
    
Gdt32Len: equ $-Gdt32

Gdt32Ptr: dw Gdt32Len-1
          dd Gdt32

; The first two bytes are the size of gdt - 1 (Length og table). The next four bytes are the address of gdt.

Idt32Ptr: dw 0
          dd 0


Gdt64:
    dq 0
    dq 0x0020980000000000; code segment descriptor entry - D L   P DPL 1 1 C - 0 1   1 00 1 1 0
; No data segment required in GDT for ring 0

; 00000000 0 01 0  0000  100110 00  000000000000000000000000   0000000000000000


; C - Confirming bit set to 0 as only non-confirming code segment used in this system
; 1 1 - means the descriptor is code segment descriptor
; DPL - privilege level (00)
; P - Present Bit - 1
; L - Long bit set to 1 indicating the code segment runs in 64-bit mode
; D - set to 0 if L set to 1

Gdt64Len: equ $-Gdt64


Gdt64Ptr: dw Gdt64Len-1
          dd Gdt64



; If CPL(Current Priveleage Level in lower 2 bits of cs and ss registers) and RPL (Requested privlege ;evel - in segment selector) less than DPL (Descriptor privilege level - in GDT Entry), check pass

; Segment Selector - 

; 15                 3   2   1     0
;    Selector Index     RPL     TI (means to use GDT)

; descritor loaded into hidden part of ds register
