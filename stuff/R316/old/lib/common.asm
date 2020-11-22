%ifndef __COMMON_ASM
%define __COMMON_ASM

%include "common"
%include "config.asm"

%macro pusha
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
%endmacro

%macro popa
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
%endmacro

%define TRUE 1
%define FALSE 0

%define shl mak
%define shr ext

%endif