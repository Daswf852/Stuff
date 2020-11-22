%ifndef __COPY_ASM
%define __COPY_ASM

%include "../common.asm"
%include "../datastack.asm"

memcpy: ; ( dst src num -- )
    push r0
    push r1
    push r2
    push r3

    dpop r2
    dpop r1
    dpop r0

    loop r3, r2, .loop, .loop_end
    .loop:
        mov [r0++], [r1++]
    .loop_end:

    pop r3
    pop r2
    pop r1
    pop r0
    ret

memmove: ; (dst src num -- )
    push r0
    push r1
    push r2
    push r3
    
    dpop r2 ;num
    dpop r1 ;src
    dpop r0 ;dst

    dpush r2
    call malloc
    dpop r3 ;intermediate array

    dpush r3
    dpush r1
    dpush r2
    call memcpy

    dpush r0
    dpush r3
    dpush r2
    call memcpy

    dpush r3
    call free

    pop r3
    pop r2
    pop r1
    pop r0

    ret

strcpy:
    ret

strncpy:
    ret

%endif