[BITS 16]
[ORG 0x7C00]

; HoloXlife Pure Ada OS Bootloader
; This is the minimal 16-bit assembly entry point that calls Ada code

start:
    ; Initialize segments
    cli                 ; Clear interrupts
    xor ax, ax         ; AX = 0
    mov ds, ax         ; DS = 0
    mov es, ax         ; ES = 0
    mov ss, ax         ; SS = 0
    mov sp, 0x7C00     ; Stack grows down from bootloader

    ; Set up video mode (80x25 color text)
    mov ax, 0x0003
    int 0x10

    ; Load kernel sectors
    mov ah, 0x02       ; Read sectors function
    mov al, HOLOGRAPHIC_KERNEL_SECTORS  ; Number of sectors to read
    mov ch, 0          ; Cylinder 0
    mov dh, 0          ; Head 0  
    mov cl, 2          ; Start from sector 2 (sector 1 is boot sector)
    mov bx, 0x8000     ; Load to 0x0000:0x8000
    int 0x13           ; BIOS disk interrupt
    jc disk_error      ; Jump if carry flag set (error)

    ; Simple GDT setup for protected mode
    lgdt [gdt_descriptor]
    
    ; Enter protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; Far jump to 32-bit code segment  
    jmp 0x08:protected_mode

disk_error:
    mov si, disk_error_msg
    call print_string
    hlt

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

disk_error_msg db "Disk read error!", 0

; GDT (Global Descriptor Table)
gdt_start:
    ; Null descriptor
    dq 0

gdt_code:
    ; Code segment descriptor
    dw 0xFFFF    ; Limit (low)
    dw 0x0000    ; Base (low)
    db 0x00      ; Base (middle)
    db 10011010b ; Access byte
    db 11001111b ; Flags + limit (high)
    db 0x00      ; Base (high)

gdt_data:
    ; Data segment descriptor  
    dw 0xFFFF    ; Limit (low)
    dw 0x0000    ; Base (low)
    db 0x00      ; Base (middle)
    db 10010010b ; Access byte
    db 11001111b ; Flags + limit (high)
    db 0x00      ; Base (high)

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size
    dd gdt_start                ; Address

[BITS 32]
protected_mode:
    ; Set up data segments
    mov ax, 0x10    ; Data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000  ; Set up stack

    ; Call Ada main procedure (linked in kernel.bin)
    call 0x8000     ; Jump to loaded kernel

    ; If Ada code returns, halt
    hlt

; Define default kernel sectors if not provided
%ifndef HOLOGRAPHIC_KERNEL_SECTORS
    %define HOLOGRAPHIC_KERNEL_SECTORS 10
%endif

; Pad to 510 bytes and add boot signature
times 510-($-$$) db 0
dw 0xAA55
