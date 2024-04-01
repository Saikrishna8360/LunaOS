section .text
global memset
global memcpy
global memmove
global memcmp


; dl is the lower 8 bits of the "d" register (edx on 32 bit machines, rdx on 64 bits) register, and sil represents the lower 8 bits of the esi register.

; refer image on how arguments are stored

memset:
    cld                 ; clear direction flag
    mov ecx, edx         ; store size in ecx (for loop counter)
    mov al, sil          ; store lower 8 bits of rsi in al register
    rep stosb           ; used to move a byte from the CPU's al register to the memory address specified by edi (the destination index register) and repeat ecx times
    ret                 ; return 

memcmp:
    cld
    xor eax, eax        ; zero eax, which will store return value
    mov ecx, edx        ; store size
    repe cmpsb          ; compare and repeat if equal (repeats till ecx is zero or a compare is unequal)
    setnz al            ; set if zero flag is cleared. So if zero flag is cleared, al is set to 1 which means the result is not equal.
    ret


; If there is a scenario where the start of the source area is before the destination and the end is in the destination, we have to copy the data backward, that is, from the last data to the first data otherwise the data at the back of the source will be replaced by the data in the front. As for other scenarios, we can simply copy data from the first to the last.
memcpy:
memmove:
    cld
    cmp rsi, rdi
    jae .copy       ; if rsi > rdi jump to .copy, else below
    mov r8, rsi     ; move rsi to r8 and add size
    add r8, rdx     
    cmp r8, rdi     ; compare end of src to start of dest, if less, .copy, else .overlap
    jbe .copy       

.overlap:       ; copy backwards
    std                 ; set direction flag
    add rdi, rdx        ; set addresses to end of values by adding size 
    add rsi, rdx
    sub rdi,1           ; decrement by 1 for accurate position
    sub rsi,1

.copy:
    mov ecx,edx         ; mov size to ecz (loop counter)
    rep movsb           ; repeat move
    cld                 ; clear direction flag
    ret                 ; return
    
