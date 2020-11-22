%ifndef __OTHER_ASM
%define __OTHER_ASM

%include "../common.asm"
%include "../datastack.asm"

memset: ; ( ptr char len -- )
    push r0
    push r1
    push r2
    push r3

    dpop r2
    dpop r1
    dpop r0

    loop r3, r2, .loop, .done
    .loop: ;4 bytes/cycle, neato!
        mov [r0++], r1
    .done:

    pop r3
    pop r2
    pop r1
    pop r0
    ret

strlen: ; ( str -- len )
    push r0
    push r1
    push r2
    push r3

    dpop r3
    mov r0, 0xFFFF
    mov r2, 0
    loop r1, r0, .loop, .loop_end
    .loop: ;1 byte / cycle + .5 ending, neat!
        add r2, 1
        cmp [r3++], 0
        cmp r3, 0
        jz .loop_end
        mov r3, mem_lc
        mov [r3], 0
    .loop_end:
    sub r2, 1
    dpush r2

    pop r3
    pop r2
    pop r1
    pop r0
    ret

%endif