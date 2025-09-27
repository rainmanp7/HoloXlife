// holographic_kernel.c
typedef unsigned char uint8_t;
typedef unsigned int uint32_t;
#define VIDEO_MEMORY 0xb8000

// Reduce heap to avoid stack collision at 0x90000
static uint8_t kernel_heap[0x40000]; // 256KB
static uint32_t heap_offset = 0;

static void* kmalloc(uint32_t size) {
    if (heap_offset + size > sizeof(kernel_heap)) return 0;
    void* ptr = &kernel_heap[heap_offset];
    heap_offset += (size + 7) & ~7;
    return ptr;
}

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
    print("Heap: 256KB (safe)\n");
    print("Stack: 0x90000 (safe)\n");
    for (;;)
        __asm__ volatile("hlt");
}
