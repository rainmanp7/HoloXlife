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
    mov sp, 0x9000

    sti

    mov [boot_drive], dl

    mov ax, 0x0003
    int 0x10

    mov si, boot_msg
    call print

    mov ax, HOLOGRAPHIC_KERNEL_OFFSET
    mov es, ax
    mov bx, 0x0000
    mov dh, HOLOGRAPHIC_KERNEL_SECTORS
    mov dl, [boot_drive]
    call disk_load

    ; Load GDT and switch to protected mode
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
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

    jmp 0x10000

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
    mov ah, 0x02       ; BIOS read sector function
    mov al, dh         ; Number of sectors to read
    mov ch, 0x00       ; Cylinder number
    mov dh, 0x00       ; Head number
    mov cl, 0x02       ; Starting sector

    int 0x13           ; Call BIOS disk services
    jc disk_error      ; Jump if carry flag set (error)

    popa
    ret

disk_error:
    mov si, disk_err_msg
    call print
    hlt

boot_msg db "[BOOT] Loading Holographic Kernel...", 0x0D, 0x0A, 0
disk_err_msg db "[ERR] Disk read failed!", 0x0D, 0x0A, 0
boot_drive db 0

HOLOGRAPHIC_KERNEL_OFFSET equ 0x1000

%ifndef HOLOGRAPHIC_KERNEL_SECTORS
HOLOGRAPHIC_KERNEL_SECTORS equ 20
%endif

gdt_start:
    dd 0x0
    dd 0x0

gdt_code:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10011010b
    db 11001111b
    db 0x0

gdt_data:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

times 510-($-$$) db 0
dw 0xaa55
