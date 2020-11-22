%ifndef __CONV_ASM
%define __CONV_ASM

itoa: ;( int -- str )
    push r0
    push r1

    dpop r0
    
    dpush 0

    loop r1, 4, .loop, .loop_end
    .loop: ;str[i] = ((num >> 4*(4-(i-1))) & 0xF) + '0'
        mov r1, [mem_lc] ;i
        sub r1, 3, r1    ;4-(i-1)
        shl r1, 2        ;4*(4-i)
        shr r1, r0, r1   ;num >> 4*(4-i)
        and r1, 0xF      ;(num >> 4*(4-i)) & 0xF

        cmp r1, 0xA
        jnge ..addZero
            add r1, '7'
            jmp ..endAdd
        ..addZero:
            add r1, '0'
        ..endAdd:

        dpush r1

    .loop_end:

    pop r1
    pop r0

    ret

%ifdef __DO_NOT_DEFINE_THIS_THANKS
itoa: ;( int -- str )
    push r0
    push r1
    push r2
    push r3

    dpop r0

    %ifndef _xtoaReturnToStack
    dpush 5
    call malloc
    dpop r1
    dpush r1 ;ret is ready

    cmp r1, 0
    jnz .notNull
        hlt
    .notNull:
    %else
    dpush 0
    %endif

    loop r2, 4, .loop, .loop_end
    .loop:
        %ifndef _xtoaReturnToStack
        mov r2, r1
        %endif
        
        ;str[i] = ((num >> 4*(4-(i-1))) & 0xF) + '0'

        %ifndef _xtoaReturnToStack
        add r2, [mem_lc] ;r2 = &str[i]
        %endif

        mov r3, [mem_lc] ;i
        sub r3, 3, r3    ;4-(i-1)
        shl r3, 2        ;4*(4-i)
        shr r3, r0, r3   ;num >> 4*(4-i)
        and r3, 0xF      ;(num >> 4*(4-i)) & 0xF

        cmp r3, 0xA
        jnge ..addZero
            add r3, '7'
            jmp ..endAdd
        ..addZero:
            add r3, '0'
        ..endAdd:

        %ifndef _xtoaReturnToStack
        mov [r2], r3
        %else
        dpush r3
        %endif

    .loop_end:

    %ifndef _xtoaReturnToStack
    add r1, 4
    mov [r1], 0 ;null term
    %else
    dpush r6 ;push pointer
    %endif

    pop r3
    pop r2
    pop r1
    pop r0

    ret
%endif

%endif