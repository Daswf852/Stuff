jmp init

%include "lib/common.asm"
%include "lib/datastack.asm"
%include "lib/stdlib.asm"
%include "lib/string.asm"
%include "lib/gfx/cga.asm"

init:
    mov r7, _stackStart
    push r0
    mov r0, atexit
    mov [r0], atexitFunc
    pop r0
    call datastack.init
    call stdlib.init
    call cga.init
    call main
halt:
    call exit

main:

    ;.loop:
    ;    call rand
    ;    and r0, [r6++], 0xFF
    ;    add r0, _terminalBufferStart
    ;    call rand
    ;    dpop r1
    ;    mov [r0], r1
    ;    jmp .loop

    ret

data:
    .str:
        dw "Hello, world!", 0

atexitFunc:
    call cga.init

    dpush .data.whoops
    call cga.puts
    call cga.newline

    dpush .data.registers
    call cga.puts
    call freeLastAllocated
    call cga.newline

    dpush r7
    dpush r6
    add r6, 1
    add [r6], 1
    sub r6, 1
    dpush r5
    dpush r4
    dpush r3
    dpush r2
    dpush r1
    dpush r0

    mov r5, 0 ;loop counter
    .regloop:
        ;test r5, 1
        ;jz ..notEven
        ;    dpush ' '
        ;    call cga.putchar
        ;..notEven:

        dpush 'R'
        call cga.putchar
        mov r1, '0'
        add r1, r5
        dpush r1
        call cga.putchar
        dpush ':'
        call cga.putchar

        dpop r0
        dpush r0
        call itoa
        call cga.puts

        dpush ' '
        call cga.putchar

        add r5, 1
        cmp r5, 8
        jnge .regloop

    dpush .data.lastElems
    call cga.puts
    call cga.newline

    mov r0, 0

    loop r1, 8, .backtraceloop, .backtraceloop_end
    .backtraceloop:
        dpush [mem_lc]
        dpush [mem_lf]
        dpush [mem_lt]
        dpush .data.spP
        call cga.puts
        dpush r0
        call itoa
        call cga.puts
        dpush .data.spPE
        call cga.puts
        mov r1, sp
        add r1, r0
        dpush [r1]
        call itoa
        call cga.puts
        call cga.newline
        add r0, 1
        dpop [mem_lt]
        dpop [mem_lf]
        dpop [mem_lc]
    .backtraceloop_end:

    ret

    .data:
        ..whoops:
            dw "Whoops, crashed!", 0
        ..lastElems:
            dw "backtrace:", 0
        ..spP:
            dw "sp+", 0
        ..spPE:
            dw ": ", 0
        ..registers:
            dw "Registers:", 0