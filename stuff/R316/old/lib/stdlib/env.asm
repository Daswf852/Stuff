abort:
    hlt
    jmp abort

atexit:
    dw abort

%define EXIT_SUCESS 0
%define EXIT_FAILURE 1

exit: ;( code -- )
    push r0
    mov r0, [atexit]
    cmp r0, 0
    pop r0
    jnz .atexitExists
        hlt
    .atexitExists:

    call [atexit]

    jmp abort
