%ifndef __SCREEN_ASM
%define __SCREEN_ASM

%include "../common.asm"

screen:
    .init:
        dpush 0x7
        dpush 0x0
        call .setColor
        dpush 0
        dpush TRUE
        call .setMode
        ret

    .setFGColor: ;( IRGB -- )
        push r0
        push r1
        mov r1, _terminalConfigColor

        dpop r0
        shl r0, 8

        and [r1], 0xF0FF
        or [r1], r0

        pop r1
        pop r0
        ret

    .setBGColor: ;( IRGB -- )
        push r0
        push r1
        mov r1, _terminalConfigColor

        dpop r0
        shl r0, 12

        and [r1], 0x0FFF
        or [r1], r0

        pop r1
        pop r0
        ret

    .setColor: ;( IRGB_FG IRGB_BG -- )
        call .setBGColor
        call .setFGColor
        ret

    .setColorPair: ;( IRGB_FG+IRGB_BG -- )
        ret

    .setMode: ; ( 0|1|2 clear -- )
        push r0
        push r1
        push r2

        dpop r0 ;clear
        dpop r1 ;mode
        mov r2, 0

        and r1, 3
        cmp r1, 3
        jnz ..correctMode
            mov r1, 0
        ..correctMode:

        and r0, 1
        shl r0, 15
        
        or r2, r0, r1
        mov r0, _terminalConfigMode
        mov [r0], r2

        pop r2
        pop r1
        pop r0
        ret

%endif