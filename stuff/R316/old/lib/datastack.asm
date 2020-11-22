%ifndef __DATASTACK_ASM
%define __DATASTACK_ASM

%include "common.asm"

%macro dpush value
    mov [--r6], value
%endmacro

%macro dpop target
    mov target, [r6++]
%endmacro

%macro ddup
    dpush r6
%endmacro

%macro ddrop
    add r6, 1
%endmacro

datastack:
    datastack.init:
        mov r6, datastack.stack
        add r6, _dataStackSize
        ret

    datastack.dropString: ; ( CString -- )
        push r0
        .loop:
            dpop r0
            cmp r0, 0
            jnz .loop
        pop r0
        ret
    
    datastack.pushStringPointer: ; ( CStringPointer -- )
        dpop r0
        loop r1, 0xFFFF, .loop, .loop_end
        .loop:
            
        .loop_end:
        ret

    datastack.stack:
        org { datastack.stack _dataStackSize + }

%endif