; boot.asm
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

    mov si, boot_msg
    call print

    call disk_load

    lgdt [gdt_descriptor]        ; FIXED: was "gdt"
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp 0x08:init_pm

[bits 32]
init_pm:
    mov ax, 0x10
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov esp, 0x90000
    call 0x10000
    jmp $

[bits 16]
print:
    pusha
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp .loop
.done:
    popa
    ret

disk_load:
    pusha
    mov bx, DAP
    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    popa
    ret

boot_msg: db "Booting...", 13, 10, 0
boot_drive: db 0

%ifndef HOLOGRAPHIC_KERNEL_SECTORS
HOLOGRAPHIC_KERNEL_SECTORS equ 4
%endif

gdt_start:
    dq 0
gdt_code:
    dw 0xFFFF
    dw 0
    db 0
    db 10011010b
    db 11001111b
    db 0
gdt_data:
    dw 0xFFFF
    dw 0
    db 0
    db 10010010b
    db 11001111b
    db 0
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

DAP:
    db 0x10, 0
    dw HOLOGRAPHIC_KERNEL_SECTORS
    dw 0x1000, 0
    dd 1

times 510-($-$$) db 0
dw 0xAA55