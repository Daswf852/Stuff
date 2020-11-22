%ifndef __STRING_ASM
%define __STRING_ASM

%include "common.asm"
%include "datastack.asm"

;memcpy, memmove, strcpy, strncpy
%include "string/copy.asm"
;%include "string/concat.asm"
;%include "string/compare.asm"
;%include "string/search.asm"
%include "string/other.asm"

%endif