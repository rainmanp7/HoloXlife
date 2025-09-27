[bits 32]
global _start
extern kmain

section .text
_start:
    mov esp, 0x90000
    call kmain
hang:
    hlt
    jmp hang