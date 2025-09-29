/* HoloXlife Pure Ada OS Linker Script */
ENTRY(_start)

SECTIONS
{
    . = 0x8000;  /* Kernel loads at 0x8000 */
    
    .text : {
        *(.text)
        *(.text.*)
    }
    
    .rodata : {
        *(.rodata)
        *(.rodata.*)
    }
    
    .data : {
        *(.data)
        *(.data.*)
    }
    
    .bss : {
        *(.bss)
        *(.bss.*)
    }
}

/* Define entry point */
_start = boot_main;
