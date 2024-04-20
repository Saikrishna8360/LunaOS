section .text
global writeu
writeu:
    sub rsp, 16         ; allocate 16 byte space in rsp for the arguments
    xor eax, eax        ; zero rax since index of system call is zero which is stored in rax

    mov [rsp], rdi      ; store the two arguments in the new allocated space in rsp
    mov [rsp+8], rsi

    mov rdi, 2          ; rdi holds arguments passed to kernel, since two arguments are passed to kernel
    mov rsi, rsp        ; rsi is pointing to address of the arguments
    int 0x80

    add rsp, 16         ; restore stack
    ret
