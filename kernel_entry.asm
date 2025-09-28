; kernel_entry.asm - Pure Ada OS entry point with port I/O functions
[bits 32]
extern emergeos_main    ; Ada procedure name
global _start
global port_out_8       ; Export port I/O functions for Ada
global port_in_8

; Port output function (for Ada)
port_out_8:
    push ebp
    mov ebp, esp
    mov dx, [ebp+8]     ; port
    mov al, [ebp+12]    ; value
    out dx, al
    pop ebp
    ret

; Port input function (for Ada)  
port_in_8:
    push ebp
    mov ebp, esp
    mov dx, [ebp+8]     ; port
    xor eax, eax
    in al, dx
    pop ebp
    ret

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
