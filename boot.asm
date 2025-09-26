; boot.asm
; This file contains the 16-bit bootloader code.
; It is responsible for loading the kernel into memory
; and transitioning to protected mode.
[org 0x7c00]
[bits 16]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    mov [boot_drive], dl
    cmp dl, 0x80
    jl invalid_drive

    mov ax, 0x0003
    int 0x10
    mov si, boot_msg
    call print

    call disk_load

    ; Load GDT and switch to protected mode
    lgdt [gdt_descriptor]        ; ← FIXED: was "gdt", should be "lgdt"
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG:init_pm

[bits 32]
init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ebp, 0x90000
    mov esp, ebp
    call 0x10000
    jmp $

[bits 16]
print:
    pusha
.print_loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp .print_loop
.done:
    popa
    ret

disk_load:
    pusha
    mov bx, DAP_struct
    mov byte [bx], 0x10          ; DAP size = 16
    mov byte [bx+1], 0x00        ; reserved
    mov word [bx+2], HOLOGRAPHIC_KERNEL_SECTORS
    mov word [bx+4], 0x0000      ; segment (ES)
    mov word [bx+6], 0x1000      ; offset (BX)
    mov dword [bx+8], 0x00000001 ; LBA = 1 (first sector after boot)
    mov dl, [boot_drive]
    mov ah, 0x42                 ; BIOS LBA extended read
    int 0x13
    jc disk_error
    popa
    ret

disk_error:
    mov si, disk_err_msg
    call print
    hlt

invalid_drive:
    mov si, invalid_drive_msg
    call print
    hlt

;===================Strings and Defines========================
boot_msg:           db "[BOOT] Loading Holographic Kernel...", 0x0D, 0x0A, 0
disk_err_msg:       db "[ERR] Disk read failed!", 0x0D, 0x0A, 0
invalid_drive_msg:  db "[ERR] Invalid boot drive!", 0x0D, 0x0A, 0
boot_drive:         db 0

; Allow override via -d
%ifndef HOLOGRAPHIC_KERNEL_SECTORS
HOLOGRAPHIC_KERNEL_SECTORS equ 20
%endif

;=========================GDT===================================
gdt_start:
    dq 0x0                      ; null descriptor

gdt_code:
    dw 0xFFFF                 ; limit low
    dw 0x0                    ; base low
    db 0x0                    ; base mid
    db 10011010b              ; access byte (code, r/x, non-system)
    db 11001111b              ; granularity + limit high
    db 0x0                    ; base high

gdt_data:
    dw 0xFFFF                 ; limit low
    dw 0x0                    ; base low
    db 0x0                    ; base mid
    db 10010010b              ; access byte (data, r/w, non-system)
    db 11001111b              ; granularity + limit high
    db 0x0                    ; base high

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1   ; limit (size - 1)
    dd gdt_start                 ; base

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

;=====================Padding and Magic Number===================
times 510 - ($ - $$) db 0
dw 0xAA55

;==========================DAP===================================
DAP_struct:
    db 0x10, 0x00             ; size, reserved
    dw HOLOGRAPHIC_KERNEL_SECTORS, 0x0000  ; sector count, reserved
    dw 0x1000, 0x0000         ; offset, segment (0x0000:0x1000 = 0x10000 linear)
    dd 0x00000001             ; LBA start
    dd 0x00000000             ; (optional 64-bit LBA high, not used here)
