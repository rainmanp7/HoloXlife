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
    mov si, boot_msg
    call print

    call disk_load

    lgdt [gdt_descriptor]
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
    jc disk_error
    popa
    ret

disk_error:
    mov si, disk_err_msg
    call print
    jmp $

boot_msg: db "Booting...", 13, 10, 0
disk_err_msg: db "Disk read error!", 13, 10, 0
boot_drive: db 0

%ifndef HOLOGRAPHIC_KERNEL_SECTORS
HOLOGRAPHIC_KERNEL_SECTORS equ 8
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
    db 0x10         ; Size of DAP
    db 0            ; Reserved
    dw HOLOGRAPHIC_KERNEL_SECTORS ; Number of sectors
    dw 0x1000       ; Buffer offset
    dw 0x0000       ; Buffer segment
    dq 1            ; Starting LBA

times 510-($-$$) db 0
dw 0xAA55
