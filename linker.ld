/* linker.ld - Ada kernel with heap at 128 KiB */
ENTRY(_start)

SECTIONS
{
    . = 0x10000;

    .text : {
        *(.text*)
    }

    .rodata : {
        *(.rodata*)
    }

    .data : {
        *(.data*)
    }

    .bss : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    }

    __kernel_end = .;

    /* Heap: 64 KiB at 128 KiB (0x20000) */
    . = 0x20000;
    __heap_start = .;
    . = 0x30000;
    __heap_end = .;

    /* Stack top at 256 KiB */
    __stack_top = 0x40000;

    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
        *(.note*)
        *(.debug*)
    }
}
