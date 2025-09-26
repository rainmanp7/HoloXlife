; kernel_entry.asm
; This file contains the 32-bit kernel entry point.
; It is responsible for setting up the stack and
; calling the kmain function (in C).
[bits 32]

global _start

extern kmain

section .text
_start:
    mov esp, 0x90000
    cld

    mov eax, 0xb8000
    mov byte [eax], 'A'
    mov byte [eax+1], 0x0F
    mov byte [eax+2], 'S'
    mov byte [eax+3], 0x0F
    mov byte [eax+4], 'M'
    mov byte [eax+5], 0x0F
    mov byte [eax+6], '!'
    mov byte [eax+7], 0x0F

    call kmain

hang:
    cli
    hlt
    jmp hang
