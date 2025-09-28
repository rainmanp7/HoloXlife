.section .text
.global load_gdt
.global enter_protected_mode

load_gdt:
    movl 4(%esp), %eax    # Get GDT pointer address
    lgdt (%eax)           # Load GDT
    ret

enter_protected_mode:
    movl %cr0, %eax       # Get CR0
    orl $1, %eax          # Set PE bit
    movl %eax, %cr0       # Enable protected mode
    ljmp $0x08, $1f       # Far jump to code segment
1:
    movw $0x10, %ax       # Load data segment selector
    movw %ax, %ds         # Set data segment registers
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss
    ret