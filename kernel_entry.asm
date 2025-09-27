; kernel_entry.asm - Pure Ada OS entry point
[bits 32]
extern emergeos_main    ; Ada procedure name
global _start

_start:
    ; Set up stack for Ada
    mov esp, 0x90000   ; Stack at 576KB
    
    ; Clear BSS section for Ada
    extern __bss_start
    extern __bss_end
    mov edi, __bss_start
    mov ecx, __bss_end
    sub ecx, edi
    xor eax, eax
    rep stosb
    
    ; Call Ada main procedure
    call emergeos_main
    
    ; Should never reach here - Ada main has infinite loop
    cli
    hlt
    jmp $
