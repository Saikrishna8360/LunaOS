[BITS 64]
[ORG 0x200000]

start:
    mov rdi, Idt
    
    mov rax, Handler0
    mov [rdi], ax
    shr rax, 16
    mov [rdi+6], ax
    shr rax, 16
    mov [rdi+8], eax

    mov rax, Timer
    add rdi, 32*16
    mov [rdi], ax
    shr rax, 16
    mov [rdi+6], ax
    shr rax, 16
    mov [rdi+8], eax

    lgdt[Gdt64Ptr]
    lidt[IdtPtr]


    push 8              ; Push segment selector
    push KernelEntry    ; Push instruction pointer
    db 0x48             ; Use 48-bit operand size for retf
    retf                ; Return far to the KernelEntry

KernelEntry:
    mov byte[0xb8000], 'K'
    mov byte[0xb8001], 0xa

InitPIT:
    mov al, (1<<2)|(3<<4)
    ; This line sets up the PIT's mode of operation by constructing a byte with specific bit settings. (1<<2) shifts the binary 1 left by 2 positions, resulting in 00000100, and (3<<4) shifts the binary 3 left by 4 positions, resulting in 00110000. Then, the bitwise OR operation combines these values into 00110100, which sets bits 2 and 4 high, configuring the PIT for mode 3 (square wave generator) with binary counting.

    out 0x43, al ; PIT configuration byte

    mov ax, 11931       ; 1193182/100 - > interrupt fired 100 times per sec
    out 0x40, al        ; set the PIT's divisor to control the frequency of its interrupts. 
    mov al, ah      
    out 0x40, al        ; completes the configuration of the PIT's divisor, setting its frequency to the desired value.

InitPIC:
    mov al, 0x11 ; configure the PICs (Programmable Interrupt Controllers) during initialization

    ; send the value of al to the control ports of both the master (0x20) and slave (0xa0) PICs.
    ; initialize the PICs in cascade mode and puts them into initialization state
    out 0x20, al
    out 0xa0, al

    ;  sets the interrupt vector offset for the master PIC.
    mov al, 32
    out 0x21, al
    ; sets the interrupt vector offset for the slave PIC.
    mov al, 40
    out 0xa1, al

    ; configure the master PIC for cascade mode.
    mov al, 4
    out 0x21, al
    ; configure the slave PIC for cascade mode.
    mov al, 2
    out 0xa1, al

    ; value enables the master PIC to receive interrupts.
    mov al, 1
    ; enabling the master and slave PICs to receive interrupts respectively.
    out 0x21, al
    out 0xa1, al

    ;  This value masks IRQ 0 on the master PIC, allowing the PICs to properly handle IRQs.
    mov al, 11111110b
    out 0x21, al
    ; This value masks IRQ 7 on the slave PIC, allowing the PICs to properly handle IRQs.
    mov al, 11111111b
    out 0xa1, al

    sti     ; enable interrupts


End:
    hlt
    jmp End

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

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
 
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

    mov byte[0xb8010], 'T'
    mov byte[0xb8011], 0xe

    jmp End

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
 
    iretq 


Gdt64:
    dq 0
    dq 0x0020980000000000   ; code segment descriptor entry - D L   P DPL 1 1 C - 0 1   1 00 1 1 0
; No data segment required in GDT for ring 0

Gdt64Len: equ $-Gdt64

Gdt64Ptr: dw Gdt64Len-1 ; GDT limit
          dq Gdt64      ; GDT base address - 8 bytes

Idt:
    %rep 256
        dw 0
        dw 0x8          ; code segment descriptor
        db 0
        db 0x8e         ; attribute
        ; Specifies the type and attributes of the interrupt gate. 0x8e indicates an interrupt gate (type) with present (P) and ring 0 privilege level (DPL=0).
        dw 0
        dd 0
        dd 0
    %endrep

IdtLen: equ $-Idt

IdtPtr: dw IdtLen-1
        dq Idt