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

    . = 0x20000;
    __heap_start = .;
    . = 0x30000;
    __heap_end = .;

    __stack_top = 0x40000;

    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
        *(.note*)
        *(.debug*)
    }
}
