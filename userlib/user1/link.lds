OUTPUT_FORMAT("elf64-x86-64")
ENTRY(start)

SECTIONS
{
    . = 400000;
	
    .text : {
        *(.text)
    }

    .rodata : {
        *(.rodata)
    }

    . = ALIGN(16);
    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}