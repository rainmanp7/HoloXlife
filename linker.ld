/* HoloXlife Pure Ada OS Linker Script - Fixed Entry Point */
ENTRY(boot_main)

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

/* Fixed: Use correct Ada export name */
_start = boot_main;
