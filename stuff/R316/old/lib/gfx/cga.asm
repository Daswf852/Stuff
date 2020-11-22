%ifndef __CGA_ASM
%define __CGA_ASM

%include "../common.asm"
%include "../datastack.asm"
%include "screen.asm"

cga:
    .init:
        push r0

        call screen.init

        mov r0, cga.cursorPos
        mov [r0], _terminalBufferStart

        pop r0

        ret

    .cursorPos:
        dw 0

    .putchar: ;( char -- )
        push r0
        mov r0, [cga.cursorPos]
        mov [r0++], [r6++]
        mov [cga.cursorPos], r0
        pop r0
        ret

    .puts: ;( CString -- )
        call cga.puts_int_basic
        ret
    
    .puts_int_basic: ;( CString -- )
        push r0
        push r1
        mov r1, [cga.cursorPos]

        ..loop:
            mov [r1++], [r6]
            cmp [r6++], 0
            jnz cga.puts_int_basic.loop
        
        mov r0, cga.cursorPos
        mov [r0], r1

        pop r1
        pop r0

        ret
    
    .linefeed: ;( -- )
        push r0
        mov r0, .cursorPos
        add [r0], 0x10
        pop r0
        ret

    .carriageReturn: ;( -- )
        push r0
        mov r0, .cursorPos
        and [r0], 0xFFF0
        pop r0
        ret

    .newline: ;( -- )
        call .carriageReturn
        call .linefeed
        ret

%endif