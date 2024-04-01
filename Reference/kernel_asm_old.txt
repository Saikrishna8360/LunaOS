section .data

section .text

start:
    mov rdi, Idt
    mov rax, Handler0
    call SetHandler
    
    mov rax, Timer
    add rdi, Idt + 32*16
    call SetHandler

    mov rdi, Idt + 32*16 + 7*16
    mov rax, SIRQ
    call SetHandler


    lgdt [Gdt64Ptr]
    lidt [IdtPtr]


; Load the TSS descriptor
SetTss:
    mov rax, Tss        ; copy Tss to rax
    mov rdi, TssDesc    ; copy TssDesc addr to rdi
    mov [rdi+2], ax     ; lower 16 bits of the address is in the third bytes of the tss descriptor.
    shr rax, 16         ; Bit 16 to 23 of the address is in the fifth bytes of the descriptor.
    mov [rdi+4], al      
    shr rax, 8          ; next part of the base address is in the 8th byte of the descriptor,
    mov [rdi+7], al     
    shr rax, 8          ; upper 32bits of the address is in the next location. We shift rax 8bits.
    mov [rdi+8], eax    ; Eax holds the upper 32bits of the address now and we move tss descriptor plus 8
    
    mov ax, 0x20        ; load selector using ltr (load task register), fifth entry so 0x20
    ltr ax


    push 8              ; Push segment selector
    push KernelEntry    ; Push instruction pointer
    db 0x48             ; Use 64-bit operand size for retf
    retf                ; Far Return to the KernelEntry

KernelEntry:
    mov byte[0xb8000], 'K'
    mov byte[0xb8001], 0xa


; PIT has 4 registers, 1 mode command register (at address 0x43) and 3 data registers for 3 channels (channel -0 (only used in this system, at address 0x40), 1, 2)
; Mode command register has 8 bits
; 7 6 5 4 3 2 1 0
; 0 0 1 1 0 1 0 0
; bit 0 -> specifies that value used by PIT is in binary
; bit 1 -3 -> operating mode (010 - rate generator used for reoccuring interrupt)
; bits 4-5 -> access mode (set the access mode to 11 which means we want to write the low byte first)
; bits 6-7 -> selecting channel (for channel 0 - 00)

InitPIT:
    mov al, (1<<2)|(3<<4)
    out 0x43, al


; we load a counter value and PIT will decrement this value at a rate of about 1.2 Mega HZ which means it will decrement the value roughly 1.2 million times per second
; For 100 interrupts per second we do 1193182/100 = 11931
    mov ax, 11931
    out 0x40, al
    mov al, ah
    out 0x40, al


; PIC also has command and data register. Each chip has its own register set. The address for the command register of the master chip is 20 and the address of the slave is a0.

; 8 bits - only bit 0 and bit 4 set to 1. bit 4 - means that this is the initialization command followed by another three initialization command words. bit 0 indicates that we use the last initialization command word
InitPIC:
    mov al, 0x11
    out 0x20, al
    out 0xa0, al

; Initialization Command Word 2 (specifies starting vector number of IRQ)
; 0-31 for processor. so we define 32
; We write this to data register which is 0x21 for Master and 0xa1 for Slave.
; Each chip has 8 IRQs, so Master starts at 32 and ends at 39, slave starts at 40

    mov al, 32
    out 0x21, al
    mov al, 40
    out 0xa1, al

; Initialization Command Word 3 (which IRQ is used to connect the two PIC chips)
; bit 2 (4) is set to specify it is set to IRQ2
; We write this to data register which is 0x21 for Master and 0xa1 for Slave.
; Slave will have idenfification which is 2

    mov al, 4
    out 0x21, al
    mov al, 2
    out 0xa1, al

; Initialization Command Word 4 (selecting mode)
; bit 0 set to 1  (x86 mode), bit 1 - automatic end of interrupt (set to 0), bits 2, 3 -    buffered mode (not used), bit - 4 fully nested mode (0),  

    mov al, 1
    out 0x21, al
    out 0xa1, al

; We mask all IRQs except IRQ0 - PIT
; To mask set corresponding bits to 1 (in data register)

    mov al, 11111110b
    out 0x21, al
    mov al, 11111111b
    out 0xa1, al

; To return to the ring3, we have to prepare 5 8-byte data on the stack.
; 1st RIP - specifies where we will return
; next Code segment selector which will load to CS register
; Then RFlags (contains status of CPU) - loaded to RFlags register
; Stack Pointer stored in next location which will be loaded to RSP register
; Last - stack segment selector 

    push 0x18|3     ; stack segment selector is 0x18 (example) - 4th descriptor, RPL is 3   
    push 0x7c00     ; stack pointer
    push 0x202      ; rflag, set bit 1 to 1 -> 10 = 2; bit 9 of rflags is the interrupt flag.
    push 0x10|3     ; code segment selector is 0x10 - 3rd descriptor, RPL - 3
    push UserEntry  ; return address is UserEntry
    iretq

End:
    hlt
    jmp End

SetHandler:
    mov [rdi], ax
    shr rax, 16
    mov [rdi+6], ax
    shr rax,16
    mov [rdi+8], eax

UserEntry:

    inc byte[0xb8010]
    mov byte[0xb8011], 0xE

UEnd:
    jmp UserEntry

Handler0:
    push rax
    push rbx  
    push rcx
    push rdx	  
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    
    mov byte[0xb8000], 'D'
    mov byte[0xb8001], 0xc

    jmp End

    pop	r15
    pop	r14
    pop	r13
    pop	r12
    pop	r11
    pop	r10
    pop	r9
    pop	r8
    pop	rbp
    pop	rdi
    pop	rsi  
    pop	rdx
    pop	rcx
    pop	rbx
    pop	rax

    iretq

Timer:
    push rax
    push rbx  
    push rcx
    push rdx  	  
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15


    inc byte[0xb8020]
    mov byte[0xb8021], 0xe
    
    mov al, 0x20        ; we write the value to the command register of the PIC. The bit 5 of the value is non-specific end of interrupt, we set it to 1.
    out 0x20, al        ; then we write it to the command register of the master (at address 0x20).
   

    pop	r15
    pop	r14
    pop	r13
    pop	r12
    pop	r11
    pop	r10
    pop	r9
    pop	r8
    pop	rbp
    pop	rdi
    pop	rsi  
    pop	rdx
    pop	rcx
    pop	rbx
    pop	rax

    iretq


SIRQ:
    push rax
    push rbx  
    push rcx
    push rdx  	  
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    mov al, 11          ; 11 - 0000 1(read method)  0 11 (specify to read ISR or IRR, 11 - ISR) 
    out 0x20, al
    in al, 0x20

    test al, 1<<7       ; test 7th bit, if it is not set then it is a spurious interrupt, end
    jz .end

    ; else acknoledge return by setting bit 5 to 1
    mov al, 0x20
    out 0x20, al

.end:       ; . -> local label
    pop	r15
    pop	r14
    pop	r13
    pop	r12
    pop	r11
    pop	r10
    pop	r9
    pop	r8
    pop	rbp
    pop	rdi
    pop	rsi  
    pop	rdx
    pop	rcx
    pop	rbx
    pop	rax

    iretq


Gdt64:
    dq 0
    dq 0x0020980000000000   ; Code segment descriptor for ring 0
    dq 0x0020f80000000000   ; code segment descriptor entry - D L   P DPL 1 1 C - 0 1   1 11 1 1 0
    dq 0x0000f20000000000   ; Data segment desctiptor entry - P DPL 1 0 0 W 0 - 1 11 1 0 0 1 0
    ; 00000000 0 00 0  0000  11110010  000000000000000000000000   0000000000000000

TssDesc:
    dw TssLen-1         ; Lower 16 bits - TSS limit
    dw 0                ; base address 0
    db 0
    db 0x89             ; Attributes -> P CPL 0 1 0 0 1 -> 1 00 0 1 0 0 1 ; (0 1 0 0 1 - specifies 64-bit TSS)
    db 0                ; rest of the fields set to 0
    db 0
    dq 0

Gdt64Len: equ $-Gdt64


Gdt64Ptr: dw Gdt64Len-1
          dq Gdt64


Idt:
    %rep 256
        dw 0
        dw 0x8          ; code segment
        db 0
        db 0x8e         ; P(1) DPL(00) 01110 (represents IDT)
        dw 0
        dd 0
        dd 0
    %endrep
; we can only jump to the code segment that is in the same privilege or higher privilege than we are currently at.
IdtLen: equ $-Idt

IdtPtr: dw IdtLen-1
        dq Idt


Tss:
    dd 0            ; 1st 4 bits reserved
    dq 0x150000     ; Address to load RSP
    times 88 db 0   ; remaining bits set to 0
    dd TssLen       ; Address of I/O permission bit map - not used

TssLen: equ $-Tss
