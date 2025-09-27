; kernel_entry.asm
[bits 32]
global _start
extern kmain
extern __bss_start
extern __bss_end

section .text
_start:
    mov esp, 0x90000
    fninit

    ; Clear BSS
    mov edi, __bss_start
    mov ecx, __bss_end
    sub ecx, edi
    jz .bss_done
    shr ecx, 2
    xor eax, eax
    rep stosd
    mov ecx, __bss_end
    sub ecx, __bss_start
    and ecx, 3
    rep stosb
.bss_done:

    cld
    call kmain

hang:
    hlt
    jmp hang
