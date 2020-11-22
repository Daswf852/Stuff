%ifndef __STDLIB_ASM
%define __STDLIB_ASM

%include "common.asm"

;malloc, free, calloc, realloc
%include "stdlib/malloc.asm"
;rand, rand.16, rand.32, srand
%include "stdlib/rand.asm"
%include "stdlib/env.asm"
%include "stdlib/conv.asm"

stdlib:
    stdlib.init:
        call malloc.init
        ret

%endif