/* HoloXlife Pure Ada OS Linker Script - Corrected Entry */
ENTRY(_ada_boot)

SECTIONS
{
    . = 0x8000;
    
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

_start = _ada_boot;
