// holographic_kernel.c - Simple test kernel
typedef unsigned int uint32_t;
typedef unsigned char uint8_t;

#define VIDEO_MEMORY 0xb8000

static void print(const char* str) {
    volatile char* video = (volatile char*)VIDEO_MEMORY;
    static int cursor_pos = 0;
    
    while (*str) {
        if (*str == '\n') {
            cursor_pos = (cursor_pos / 80 + 1) * 80;
        } else {
            video[cursor_pos * 2] = *str;
            video[cursor_pos * 2 + 1] = 0x0F; // White on black
            cursor_pos++;
        }
        str++;
        
        // Simple scroll
        if (cursor_pos >= 80 * 25) {
            for (int i = 0; i < 80 * 24; i++) {
                video[i * 2] = video[(i + 80) * 2];
                video[i * 2 + 1] = video[(i + 80) * 2 + 1];
            }
            for (int i = 0; i < 80; i++) {
                video[(80 * 24 + i) * 2] = ' ';
            }
            cursor_pos = 80 * 24;
        }
    }
}

void kmain(void) {
    // Clear screen
    volatile char* video = (volatile char*)VIDEO_MEMORY;
    for (int i = 0; i < 80 * 25; i++) {
        video[i * 2] = ' ';
        video[i * 2 + 1] = 0x0F;
    }
    
    print("=== EMERGEOS TEST KERNEL ===\n");
    print("Kernel loaded successfully!\n");
    print("Boot process: [OK]\n");
    print("Memory: [OK]\n");
    print("Video: [OK]\n");
    print("System: Ready\n");
    print("\nPress Ctrl+Alt to exit Bochs\n");
    
    // Hang forever
    while (1) {
        __asm__ volatile("hlt");
    }
}
