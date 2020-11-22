%ifndef __MALLOC_ASM
%define __MALLOC_ASM

%include "../common.asm"
%include "../datastack.asm"

malloc: ;( size -- pointer)
    push r0
    call .getFirstEmptyEntry ;check if there's a suitable entry spot
    dpop r0
    cmp r0, 0xFFFF
    jne .emptyEntryExists
        dpop r0 ;clear data stack
        dpush 0
        pop r0
        ret
    .emptyEntryExists:

    push r1
    push r2
    push r3
    push r4
    push r5

    dpop r0   ;requestedSize
    mov r1, 0 ;currentIDX
    mov r2, 0 ;trackedSize
    mov r5, 0 ;return value

    mov r3, 0 ;loopIndex
    .loop:

        ;call .entryExistsAtHeapIndex
        ;dpop r4
        ;cmp r4, 0
        dpush r3
        call .findEntryAtIndex
        dpop r4
        cmp r4, 0xFFFF
        jz malloc.loop.noEntryAtIndex
            mov r2, 0
            mov r1, 0

            add r4, .sizeTable
            add r3, [r4]

            jmp malloc.loop.continue
        ..noEntryAtIndex:
            cmp r2, 0
            jnz malloc.loop.noEntryAtIndex.trackedSizeIsntZero
                mov r1, r3
            ...trackedSizeIsntZero:
            
            add r2, 1
            cmp r2, r0
            jne malloc.loop.noEntryAtIndex.sizeRequirementNotMet
                ;woot
                dpush r1
                dpush r0
                call .insertEntry
                add r5, r1, malloc.heap
                jmp malloc.loop_end
            ...sizeRequirementNotMet:

        ..continue:
        add r3, 1
        cmp r3, _heapSize
        jnge .loop
    .loop_end:

    dpush r5

    mov r4, .lastAllocated
    mov [r4], 0
    cmp r5, 0
    jz .notAllocated
        mov [r4], r5
    .notAllocated:

    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret

    ;unused, use getEntryAtHeapIndex
    .findEntryAtIndex: ;( heapIndex -- bool )
        push r0
        push r1
        push r2
        push r3
        mov r3, 0 ;default return value

        dpop r1
        
        ;BEWARE: COUNTS BACKWARDS
        loop r0, _heapPointerTableSize, ..loop, ..done
        ..loop:
            mov r2, malloc.indexTable    ;get indexTable[tableIDX]
            add r2, [mem_lc]
            cmp r2, r1                          ;check indexTable[tableIDX] == heapIndex
            jne ...not_equal
                mov r3, 1                       ;set return value to true
                mov r2, mem_lc                  ;disable looping
                mov [r2], 0
            ...not_equal:
        ..done:

        dpush r3

        pop r3
        pop r2
        pop r1
        pop r0
        ret

    .findEntryAtIndex: ;( heapIndex -- tableIndex )
        push r0
        push r1
        push r2
        push r3

        mov r3, 0xFFFF
        dpop r0
        loop r1, _heapPointerTableSize, ..loop, ..loop_end
        ..loop:
            mov r2, [mem_lc]
            add r2, malloc.indexTable
            cmp r0, [r2]
            jne ..loop_end
                ;woot
                mov r3, [mem_lc] ;set return value
                mov r2, mem_lc
                mov [r2], 0 ;disable loop
        ..loop_end:

        dpush r3

        pop r3
        pop r2
        pop r1
        pop r0
        ret

    .getFirstEmptyEntry: ;( -- tableIndex)
        push r0
        push r1
        push r2
        mov r1, 0xFFFF ;default return value

        ;BEWARE: COUNTS BACKWARDS
        loop r0, _heapPointerTableSize, malloc.getFirstEmptyEntry.loop, malloc.getFirstEmptyEntry.done
        ..loop:
            mov r2, malloc.indexTable    ;get indexTable[tableIDX]
            add r2, [mem_lc]
            cmp [r2], 0xFFFF                    ;check indexTable[tableIDX] == 0xFFFF
            jne ...not_zero
                mov r1, [mem_lc]                ;set return value to current table index
                mov r2, mem_lc                  ;disable looping
                mov [r2], 0
            ...not_zero:
        ..done:

        dpush r1

        pop r2
        pop r1
        pop r0
        ret

    .insertEntry: ;( heapIndex size -- )
        push r0
        push r1
        push r2
        push r3

        dpop r1
        dpop r0
        call malloc.getFirstEmptyEntry
        dpop r2

        mov r3, malloc.indexTable
        add r3, r2
        mov [r3], r0

        mov r3, malloc.sizeTable
        add r3, r2
        mov [r3], r1

        pop r3
        pop r2
        pop r1
        pop r0

        ret

    .init:
        push r0
        push r1
        mov r0, .indexTable
        loop r1, _heapPointerTableSize, ..loop, ..loop_end
        ..loop:
            mov [r0++], 0xFFFF
        ..loop_end:
        pop r1
        pop r0
        ret

    .indexTable:
        org { malloc.indexTable _heapPointerTableSize + }
    
    .sizeTable:
        org { malloc.sizeTable _heapPointerTableSize + }

    .heap:
        org { malloc.heap _heapSize + }

    .lastAllocated:
        dw 0

free: ;( pointer -- )
    push r0

    dpop r0
    sub r0, malloc.heap
    dpush r0
    call malloc.findEntryAtIndex
    dpop r0
    cmp r0, 0xFFFF
    jne .validPointer
        call abort
        pop r0
        ret
    .validPointer:
        add r0, malloc.indexTable
        mov [r0], 0xFFFF
        mov r0, malloc.lastAllocated
        mov [r0], 0

    pop r0
    ret

;for convineance
freeLastAllocated: ;( -- )
    push r0
    mov r0, [malloc.lastAllocated]
    cmp r0, 0
    jz .dontFree
        dpush r0
        call free
    .dontFree:
    pop r0
    ret

calloc: ; ( num size -- pointer )
    dpush 0
    ret

calloc_nonstd: ; ( size -- pointer )
    push r0
    push r1

    dpop r0
    dpush r0 ;size
    call malloc
    dpop r1
    dpush r1

    dpush 0
    dpush r0
    call memset

    dpush r1

    pop r1
    pop r0
    ret


%endif