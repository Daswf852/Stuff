%ifndef __RAND_ASM
%define __RAND_ASM

rand:
.word: ;( -- byte)
    push r0
    push r1
    mov r1, [.seed]

    mov r0, r1
    shl r0, 7
    xor r1, r0

    mov r0, r1
    shr r0, 9
    xor r1, r0

    mov r0, r1
    shl r0, 8
    xor r1, r0

    mov [.seed], r1

    dpush r1

    pop r1
    pop r0
    ret
.dword: ;( -- highbyte lowbyte)
    dpush 0xBEEF
    dpush 0xDEAD
    ret
    .seed:
        dw 0xDEAD
        ;dw 0xBEEF
srand: ; (seed -- )
    dpop [rand.seed]
    ret
%endif