/* linker.ld */
ENTRY(_start)

SECTIONS
{
    /* Kernel loaded at 1 MiB (standard for protected-mode kernels) */
    . = 0x100000;

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

    /* Reserve 1 MiB for heap starting at 2 MiB */
    . = 0x200000;
    __heap_start = .;
    . = 0x300000;        /* 1 MiB heap */
    __heap_end = .;

    /* Stack grows downward from 3 MiB */
    __stack_top = 0x300000;

    /* Ensure image doesn't exceed safe limit */
    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
        *(.note*)
    }
}
