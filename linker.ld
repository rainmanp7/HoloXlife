/* linker.ld - Improved for Ada kernel with heap */
ENTRY(_start)

SECTIONS
{
    /* Kernel loaded at 64 KiB (0x10000) - matches your current bootloader */
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

    /* End of kernel image */
    __kernel_end = .;

    /* Reserve 64 KiB heap starting at 128 KiB (0x20000) */
    . = 0x20000;
    __heap_start = .;
    . = 0x30000;        /* 64 KiB heap (128 KiB → 192 KiB) */
    __heap_end = .;

    /* Stack grows downward from 256 KiB (0x40000) */
    __stack_top = 0x40000;

    /* Discard debug and exception metadata (not needed in freestanding) */
    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
        *(.note*)
        *(.debug*)
    }
}
