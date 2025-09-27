; kernel_entry.asm
[bits 32]
extern _Ada_Main
global _start

; Serial port constants
%define SERIAL_PORT 0x3F8

; Initialize serial port (COM1)
init_serial:
    mov dx, SERIAL_PORT
    add dx, 1
    mov al, 0x00
    out dx, al          ; Disable interrupts
    mov dx, SERIAL_PORT
    add dx, 3
    mov al, 0x80        ; Enable DLAB (set baud rate)
    out dx, al
    mov dx, SERIAL_PORT
    mov al, 0x03        ; Low byte of divisor (115200 baud)
    out dx, al
    mov dx, SERIAL_PORT
    add dx, 1
    mov al, 0x00        ; High byte of divisor
    out dx, al
    mov dx, SERIAL_PORT
    add dx, 3
    mov al, 0x03        ; 8 bits, no parity, one stop bit
    out dx, al
    mov dx, SERIAL_PORT
    add dx, 2
    mov al, 0xC7        ; Enable FIFO, clear them, 14-byte threshold
    out dx, al
    ret

; Send character via serial
serial_putchar:
    push dx
    push ax
.wait:
    mov dx, SERIAL_PORT + 5
    in al, dx
    and al, 0x20
    jz .wait
    mov dx, SERIAL_PORT
    pop ax
    out dx, al
    pop dx
    ret

_start:
    ; Initialize serial
    call init_serial

    ; Set up stack
    mov esp, 0x40000   ; Stack top at 256 KiB

    ; Call Ada main
    call _Ada_Main

    ; Halt
    hlt
    jmp $
