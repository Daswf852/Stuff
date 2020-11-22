%ifndef __CONFIG_ASM
%define __CONFIG_ASM

%define _terminalBufferStart 0x1C00
;0xBF.. -> F=Foreground, B=Background
%define _terminalConfigColor 0x1D00
;0xC00M -> C=Clear(8|0), M=Mode(0|1|2)
%define _terminalConfigMode  0x1D01

%define _dataStackSize 128

%define _stackStart 0x800

%define _heapSize 512
%define _heapPointerTableSize 16

;deprecated
%define _xtoaReturnToStack

;uncomment to disable malloc
;%define __MALLOC_ASM

%endif