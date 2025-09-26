/* linker.ld */
ENTRY(_start)
SECTIONS
{
    . = 0x10000;

    .text : {
        *(.text)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }

    /* --- Reserve 768KB for the kernel heap at 0xA0000 --- */
    . = 0xA0000;
    kernel_heap_start = .;
    . += 0xC0000;  /* 768KB — hard-coded numeric value */

    /DISCARD/ : {
        *(.comment)
        *(.note*)
    }
}
