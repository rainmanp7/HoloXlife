#define VIDEO_MEMORY 0xB8000

static void print(const char* str) {
    volatile char* vga = (volatile char*)VIDEO_MEMORY;
    static int pos = 0;
    while (*str) {
        if (*str == '\n') {
            pos = (pos / 80 + 1) * 80;
        } else {
            vga[pos * 2] = *str;
            vga[pos * 2 + 1] = 0x0F;
            pos++;
        }
        if (pos >= 80 * 25) {
            for (int i = 0; i < 80 * 24 * 2; i++)
                vga[i] = vga[i + 160];
            for (int i = 0; i < 80 * 2; i++)
                vga[3840 + i] = (i % 2) ? 0x0F : ' ';
            pos = 24 * 80;
        }
        str++;
    }
}

void kmain(void) {
    print("=== EMERGEOS BOOTED ===\n");
    print("SUCCESS: Kernel is running!\n");
    for (;;)
        __asm__ volatile("hlt");
}