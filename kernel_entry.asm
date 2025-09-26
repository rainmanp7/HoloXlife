; kernel_entry.asm
; 32-bit kernel entry point: set up stack, clear BSS, init FPU, call kmain
[bits 32]
global _start
extern kmain
extern __bss_start
extern __bss_end

section .text
_start:
    ; Set up 32-bit stack at 0x90000 (consistent with bootloader)
    mov esp, 0x90000

    ; Initialize FPU (required before any float use)
    fninit

    ; Clear BSS section to zero
    mov edi, __bss_start
    mov ecx, __bss_end
    sub ecx, edi
    jz .bss_done
    shr ecx, 2          ; convert byte count to dword count
    xor eax, eax
    rep stosd           ; store EAX into [EDI], ECX times
    ; Handle remaining bytes (if any)
    mov ecx, __bss_end
    sub ecx, __bss_start
    and ecx, 3
    rep stosb
.bss_done:

    ; Ensure forward direction for string ops
    cld

    ; Jump to C code
    call kmain

hang:
    cli
    hlt
    jmp hang
