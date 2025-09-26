// kernel.c - Enhanced Holographic Kernel with Dynamic Manifolds, Genomes, and Emergent Behavior
// IRQ AND UART DISABLED ON BOOT kmain
// To stop crashing memory conflicts.
// --- TYPE DEFINITIONS ---
typedef unsigned char   uint8_t;
typedef unsigned short  uint16_t;
typedef unsigned int    uint32_t;
typedef unsigned int    size_t;
typedef unsigned long   uintptr_t;
#ifndef NULL
#define NULL ((void *)0)
#endif
// --- ENHANCED HOLOGRAPHIC MEMORY CONFIGURATION ---
#define INITIAL_DIMENSIONS 512
#define MAX_DIMENSIONS 2048
#define HOLOGRAPHIC_MEMORY_BASE 0xA0000
#define HOLOGRAPHIC_MEMORY_SIZE 0x10000
#define MAX_MEMORY_ENTRIES 128
#define MAX_ENTITIES 32
#define INITIAL_ENTITIES 3
#define MAX_ENTITY_DOMAINS 8
#define MAX_THOUGHTS 64
#define MAX_GENES_PER_ENTITY 16
// --- VIDEO MEMORY ---
#define VIDEO_MEMORY 0xb8000
// --- Structure definitions (must come before function prototypes) ---
typedef struct {
    float* data;           // Dynamically allocated array
    uint32_t capacity;     // Current max dimensions
    uint32_t active_dims;  // Actually used dimensions
    uint32_t hash_sig;     // Hash of the active subspace
    uint8_t valid;
} HyperVector;
typedef struct Gene {
    HyperVector pattern;          // The gene itself (e.g., a hardware signature)
    struct Gene* next;            // Next gene in the sequence
    uint32_t fitness;             // How well this gene works
    uint8_t mutable;              // Can this gene be mutated?
    char name[16];                // Debug name for the gene
} Gene;
struct Entity {
    uint32_t id;
    HyperVector state;
    struct Gene* genome;          // Dynamic genome (linked list of genes)
    uint32_t gene_count;
    uint32_t age;
    uint32_t interaction_count;
    uint8_t is_active;
    float specialization_scores[MAX_ENTITY_DOMAINS];
    float resource_allocation;
    float confidence;
    char domain_name[32];
    // Task & Path Assignment
    HyperVector task_vector;
    uint32_t path_id;
    float task_alignment;
    // Evolution & Fitness
    uint32_t fitness_score;
    uint32_t spawn_count;
    uint8_t marked_for_gc;
    uint8_t is_mutant;
    uint32_t mutation_rate;       // Entities control their own evolution (0-1000)
};
struct CollectiveConsciousness {
    HyperVector thought_space[MAX_THOUGHTS]; // Shared "mind"
    uint32_t thought_count;
    float global_coherence;       // How aligned thoughts are
};
typedef struct {
    uint32_t task_id;
    uint32_t data[4];
    uint8_t valid;
} Task;
typedef struct {
    HyperVector input_pattern;
    HyperVector output_pattern;
    uint32_t timestamp;
    uint8_t valid;
} MemoryEntry;
typedef struct {
    HyperVector pattern;      // The "before" state (e.g., a function signature)
    HyperVector replacement;  // The "after" state (e.g., a mutated function)
    uint32_t address;         // Memory address to patch
    uint8_t applied;          // Has this patch been applied?
} KernelPatch;
struct HardwareInfo {
    char cpu_vendor[13];
    uint32_t cpu_features;
    uint32_t memory_kb;
    int device_count;
};
struct HolographicSystem {
    MemoryEntry memory_pool[MAX_MEMORY_ENTRIES];
    uint32_t memory_count;
    uint32_t global_timestamp;
};
// --- KERNEL HEAP MEMORY MANAGEMENT ---
static uint8_t kernel_heap[0xC0000]; // 128KB heap — KEEP ORIGINAL SIZE FOR STABILITY
static uint32_t heap_offset = 0;

// --- NEW FUNCTION: Get remaining free heap space ---
static size_t heap_get_free_space(void) {
    return sizeof(kernel_heap) - heap_offset;
}

// --- PORT I/O FUNCTIONS (static inline) ---
static inline void outb(uint16_t port, uint8_t value) {
    __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}
static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    __asm__ volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

// --- SERIAL PORT FUNCTIONS ---
static void serial_write(char c) {
    // Wait for the transmit buffer to be empty (bit 5 of Line Status Register)
    while ((inb(0x3F8 + 5) & 0x20) == 0);
    outb(0x3F8, c);
}

// --- FIXED: Define serial_print BEFORE kmalloc ---
static void serial_print(const char* str) {
    while (*str) {
        serial_write(*str++);
    }
}
// --- END FIXED SECTION ---

// --- VGA TEXT MODE FUNCTIONS ---
static void print_char(char c, uint8_t color) {
    volatile char* video = (volatile char*)VIDEO_MEMORY;
    static uint16_t cursor_pos = 0;
    uint16_t pos_offset;
    if (c == '\n') {
        // Move to the beginning of the next line
        cursor_pos = (cursor_pos / 80 + 1) * 80;
    } else {
        pos_offset = cursor_pos * 2;
        video[pos_offset] = c;
        video[pos_offset + 1] = color;
        cursor_pos++;
    }
    // Simple scroll: if we've reached the end of the screen buffer
    if (cursor_pos >= 80 * 25) {
        // Move lines 1-24 down to lines 0-23
        for (size_t i = 0; i < 80 * 24; i++) {
            video[i * 2] = video[(i + 80) * 2];
            video[i * 2 + 1] = video[(i + 80) * 2 + 1];
        }
        // Clear the last line (line 24)
        for (size_t i = 0; i < 80; i++) {
            video[(80 * 24 + i) * 2] = ' ';
            video[(80 * 24 + i) * 2 + 1] = color; // Use current color
        }
        cursor_pos = 80 * 24; // Position cursor at the start of the new blank line
    }
}

static void print(const char* str) {
    while (*str) {
        print_char(*str++, 0x0F); // White text on black background
    }
}

// --- FIXED: Define print_hex BEFORE kmalloc ---
static void print_hex(uint32_t value) {
    char hex_chars[] = "0123456789ABCDEF";
    char hex_str[11]; // 0x + 8 chars + null terminator
    hex_str[10] = '\0';
    int i;
    // Fill the string from the end
    for (i = 9; i >= 2; i--) {
        hex_str[i] = hex_chars[value & 0x0F];
        value >>= 4;
    }
    hex_str[0] = '0';
    hex_str[1] = 'x';
    print(hex_str);
}
// --- END FIXED SECTION ---

static void* kmalloc(size_t size) {
    if (heap_offset + size >= sizeof(kernel_heap)) {
        // --- CRITICAL: LOG THE FAILURE ---
        serial_print("[CRITICAL] kmalloc FAILED! Requested: ");
        print_hex(size);
        serial_print(" bytes. Free space: ");
        print_hex(heap_get_free_space());
        serial_print(" bytes.\n");
        return NULL; // Out of memory
    }
    void* ptr = &kernel_heap[heap_offset];
    heap_offset += (size + 7) & ~7; // 8-byte align
    return ptr;
}

static void kfree(void* ptr) {
    // Simple allocator - no actual free for now
    // In a real kernel, implement a proper allocator
    (void)ptr; // Suppress unused parameter warning
}

static void* memcpy(void* dest, const void* src, size_t n) {
    uint8_t* d = (uint8_t*)dest;
    const uint8_t* s = (const uint8_t*)src;
    for (size_t i = 0; i < n; i++) {
        d[i] = s[i];
    }
    return dest;
}

static void* memset(void* ptr, int value, size_t n) {
    uint8_t* p = (uint8_t*)ptr;
    for (size_t i = 0; i < n; i++) {
        p[i] = (uint8_t)value;
    }
    return ptr;
}

static void serial_init(void) {
    // Initialize COM1 serial port (0x3F8)
    outb(0x3F8 + 1, 0x00); // Disable interrupts
    outb(0x3F8 + 3, 0x80); // Enable DLAB (Divisor Latch Access Bit)
    outb(0x3F8 + 0, 0x03); // Set divisor to 3 (lo byte) for 38400 baud
    outb(0x3F8 + 1, 0x00); //                  (hi byte)
    outb(0x3F8 + 3, 0x03); // 8 bits, no parity, one stop bit
    outb(0x3F8 + 2, 0xC7); // Enable FIFO, clear them, with 14-byte threshold
// IRQ DISABLED
    //outb(0x3F8 + 4, 0x0B); // IRQs enabled, RTS/DSR set
    // Send a test character to ensure the port is initialized
    serial_write('S');
    serial_write('E');
    serial_write('R');
    serial_write(' ');
    serial_write('O');
    serial_write('N');
    serial_write('\n');
}

// --- Enhanced Math Functions ---
static float sqrtf(float x) {
    if (x <= 0.0f) return 0.0f;
    float x_half = 0.5f * x;
    union {
        float f;
        uint32_t i;
    } u;
    u.f = x;
    u.i = 0x5f3759df - (u.i >> 1);
    x = u.f;
    x = x * (1.5f - x_half * x * x);
    return 1.0f / x;
}

static size_t strlen(const char *str) {
    const char *s;
    for (s = str; *s; ++s);
    return (s - str);
}

static char *strncpy(char *dest, const char *src, size_t n) {
    size_t i;
    for (i = 0; i < n && src[i] != '\0'; i++)
        dest[i] = src[i];
    for ( ; i < n; i++)
        dest[i] = '\0';
    return dest;
}

//---Function Prototypes---
void kmain(void) __attribute__((noreturn));
static uint32_t hash_data(const void* input, uint32_t size);
// HyperVector functions
static HyperVector create_hyper_vector(const void* input, uint32_t size);
static void grow_manifold(HyperVector* vec, uint32_t new_capacity);
static void destroy_hyper_vector(HyperVector* vec);
static float compute_similarity(HyperVector* a, HyperVector* b);
static void merge_hyper_vectors(HyperVector* dest, HyperVector* src);
// Genome functions
static struct Gene* create_gene(const char* name, HyperVector pattern);
static void mutate_gene(struct Gene* gene, float rate);
static struct Gene* invent_gene(HyperVector pattern);
static void add_gene_to_entity(struct Entity* entity, struct Gene* gene);
static void destroy_genome(struct Gene* genome);
// Collective consciousness functions
static void initialize_collective_consciousness(void);
static void broadcast_thought(HyperVector* thought);
static float compute_coherence(HyperVector* thought);
// Holographic memory functions
static void encode_holographic_memory(HyperVector* input, HyperVector* output);
static HyperVector* retrieve_holographic_memory(uint32_t hash);
static void initialize_holographic_memory(void);
static void load_initial_genome_vocabulary(void);
// Entity management functions
static void initialize_emergent_entities(void);
static struct Entity* spawn_entity(void);
static void update_entities(void);
static void render_entities_to_vga(void);
// Hardware probing functions
static void probe_hardware(void);
// Memory access functions
static void set_memory_value(uint32_t address, uint8_t value);
static uint8_t get_memory_value(uint32_t address);
// --- PHASE 4: Self-Modifying Kernel Functions ---
static void apply_kernel_patch(KernelPatch* patch);
static void propose_kernel_patch(struct Entity* entity, HyperVector* old_pattern, HyperVector* new_pattern, uint32_t address);
// Global variables (all static, with consistent initialization)
static struct Entity entity_pool[MAX_ENTITIES];
static uint32_t active_entity_count = 0;
static struct HolographicSystem holo_system = {0};
static struct CollectiveConsciousness collective = {0};
// Update entity state storage (moved from stack to avoid overflow)
static uint8_t next_active[MAX_ENTITIES];
static HyperVector next_state[MAX_ENTITIES];
static char next_domain[MAX_ENTITIES][32];
static HyperVector next_task_vector[MAX_ENTITIES];
static uint32_t next_path_id[MAX_ENTITIES];
static float next_task_alignment[MAX_ENTITIES];

//---Kernel starting point---
void kmain(void) {
    volatile char* video = (volatile char*)VIDEO_MEMORY;
    video[0] = 'H';
    video[1] = 0x0F;
    video[2] = 'Y';
    video[3] = 0x0F;
    video[4] = 'P';
    video[5] = 0x0F;
    video[6] = 'E';
    video[7] = 0x0F;
    video[8] = 'R';
    video[9] = 0x0F;
    serial_init();
    serial_print("DEBUG: Serial initialized, HyperKernel starting!\n");
__asm__ volatile ("cli"); // Disable interrupts
    serial_print("Hyperdimensional Kernel (Dynamic Manifolds + Genomes) Starting...\n");
    print("Hyperdimensional Kernel (Dynamic Manifolds + Genomes) Starting...\n");
    print("Initializing dynamic hyperdimensional memory system...\n");
    initialize_holographic_memory();
    initialize_collective_consciousness();
    load_initial_genome_vocabulary();
    initialize_emergent_entities();
    // Assign Initial Task Vectors with dynamic expansion
    HyperVector path_vector = create_hyper_vector("network_io_path", strlen("network_io_path") + 1);
    for (uint32_t i = 0; i < active_entity_count && i < 2; i++) {
        entity_pool[i].task_vector = path_vector;
        entity_pool[i].path_id = 0xA1;
        entity_pool[i].mutation_rate = 100; // 10% mutation rate
        serial_print("[TASK] Assigned dynamic path 0xA1 to entity ");
        print_hex(entity_pool[i].id);
        serial_print("\n");
    }
    print("Hyperdimensional Kernel with Dynamic Genomes Initialized!\n");
    print("System entering emergent entity loop with collective consciousness...\n");
    serial_print("[BOOT] HyperKernel fully initialized. Evolution engine online.\n");
    uint32_t last_update = 0;
    uint32_t update_interval = 500000;
    while (1) {
        if (holo_system.global_timestamp - last_update > update_interval) {
            update_entities();
            render_entities_to_vga();
            last_update = holo_system.global_timestamp;
        }
        holo_system.global_timestamp++;
        __asm__ volatile("hlt");
    }
}

//---Hash function (FNV-1a)---
static uint32_t hash_data(const void* input, uint32_t size) {
    const uint8_t* data = (const uint8_t*)input;
    uint32_t hash = 2166136261U;
    for (uint32_t i = 0; i < size; i++) {
        hash ^= data[i];
        hash *= 16777619U;
    }
    return hash;
}

//---PHASE 1: Dynamic Hyperdimensional Manifold Functions---
static HyperVector create_hyper_vector(const void* input, uint32_t size) {
    HyperVector vec = {0};
    vec.capacity = INITIAL_DIMENSIONS;
    vec.data = (float*)kmalloc(vec.capacity * sizeof(float));
    vec.active_dims = 0;
    vec.valid = 1;
    // --- ADD THIS CHECK ---
    if (!vec.data) {
        serial_print("[ERROR] create_hyper_vector: Out of memory!\n");
        vec.valid = 0;
        return vec;
    }
    // Initialize with zeros
    memset(vec.data, 0, vec.capacity * sizeof(float));
    uint32_t seed = hash_data(input, size);
    vec.hash_sig = seed;
    for (uint32_t i = 0; i < vec.capacity; i++) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        if ((seed % 10) == 0) {
            vec.data[i] = ((float)((seed % 2000) - 1000)) / 1000.0f;
            vec.active_dims++;
        }
    }
    // Re-hash active subspace
    vec.hash_sig = hash_data(vec.data, vec.active_dims * sizeof(float));
    return vec;
}

static void grow_manifold(HyperVector* vec, uint32_t new_capacity) {
    if (!vec || !vec->valid || new_capacity <= vec->capacity || new_capacity > MAX_DIMENSIONS) {
        return;
    }
    float* new_data = (float*)kmalloc(new_capacity * sizeof(float));
    if (!new_data) {
        serial_print("[ERROR] Failed to grow manifold - out of memory\n");
        return;
    }
    // Copy existing data
    memcpy(new_data, vec->data, vec->capacity * sizeof(float));
    // Zero out new dimensions
    memset(new_data + vec->capacity, 0, (new_capacity - vec->capacity) * sizeof(float));
    // Note: In a real kernel, we'd free the old data
    // kfree(vec->data);
    vec->data = new_data;
    vec->capacity = new_capacity;
    vec->hash_sig = hash_data(vec->data, vec->active_dims * sizeof(float));
    serial_print("[GROW] Manifold expanded to ");
    print_hex(new_capacity);
    serial_print(" dimensions\n");
}

static void destroy_hyper_vector(HyperVector* vec) {
    if (vec && vec->data) {
        kfree(vec->data);
        vec->data = NULL;
        vec->valid = 0;
    }
}

static float compute_similarity(HyperVector* a, HyperVector* b) {
    if (!a || !b || !a->valid || !b->valid || !a->data || !b->data) {
        return 0.0f;
    }
    uint32_t min_dims = (a->active_dims < b->active_dims) ? a->active_dims : b->active_dims;
    if (min_dims == 0) return 0.0f;
    float dot = 0.0f;
    float mag_a = 0.0f, mag_b = 0.0f;
    for (uint32_t i = 0; i < min_dims; i++) {
        dot += a->data[i] * b->data[i];
        mag_a += a->data[i] * a->data[i];
        mag_b += b->data[i] * b->data[i];
    }
    mag_a = (mag_a > 0) ? sqrtf(mag_a) : 1.0f;
    mag_b = (mag_b > 0) ? sqrtf(mag_b) : 1.0f;
    return (mag_a * mag_b > 0) ? (dot / (mag_a * mag_b)) : 0.0f;
}

static void merge_hyper_vectors(HyperVector* dest, HyperVector* src) {
    if (!dest || !src || !dest->valid || !src->valid) return;
    uint32_t min_dims = (dest->active_dims < src->active_dims) ? dest->active_dims : src->active_dims;
    for (uint32_t i = 0; i < min_dims; i++) {
        dest->data[i] = (dest->data[i] + src->data[i]) * 0.5f; // Average merge
    }
    dest->hash_sig = hash_data(dest->data, dest->active_dims * sizeof(float));
}

//---PHASE 2: Self-Modifying Genome Functions---
static struct Gene* create_gene(const char* name, HyperVector pattern) {
    struct Gene* gene = (struct Gene*)kmalloc(sizeof(struct Gene));
    // --- ADD THIS CHECK ---
    if (!gene) {
        serial_print("[ERROR] create_gene: Out of memory!\n");
        return NULL;
    }
    gene->pattern = pattern;
    gene->next = NULL;
    gene->fitness = 0;
    gene->mutable = 1;
    strncpy(gene->name, name, 15);
    gene->name[15] = '\0';
    return gene;
}

static void mutate_gene(struct Gene* gene, float rate) {
    if (!gene || !gene->mutable || !gene->pattern.valid) return;
    uint32_t mutations = 0;
    for (uint32_t i = 0; i < gene->pattern.active_dims; i++) {
        if (((holo_system.global_timestamp * 1103515245 + i) % 1000) < (uint32_t)(rate * 1000)) {
            gene->pattern.data[i] += ((float)(((holo_system.global_timestamp + i) % 2000) - 1000)) / 10000.0f;
            gene->fitness = 0; // Reset fitness after mutation
            mutations++;
        }
    }
    if (mutations > 0) {
        gene->pattern.hash_sig = hash_data(gene->pattern.data, gene->pattern.active_dims * sizeof(float));
        serial_print("[MUTATE] Gene ");
        serial_print(gene->name);
        serial_print(" mutated ");
        print_hex(mutations);
        serial_print(" dimensions\n");
    }
}

static struct Gene* invent_gene(HyperVector pattern) {
    struct Gene* new_gene = (struct Gene*)kmalloc(sizeof(struct Gene));
    if (!new_gene) return NULL;
    new_gene->pattern = pattern;
    new_gene->next = NULL;
    new_gene->fitness = 0;
    new_gene->mutable = 1;
    strncpy(new_gene->name, "invented", 15);
    new_gene->name[15] = '\0';
    return new_gene;
}

static void add_gene_to_entity(struct Entity* entity, struct Gene* gene) {
    if (!entity || !gene || entity->gene_count >= MAX_GENES_PER_ENTITY) return;
    // Add to front of linked list
    gene->next = entity->genome;
    entity->genome = gene;
    entity->gene_count++;
    serial_print("[GENOME] Added gene ");
    serial_print(gene->name);
    serial_print(" to entity ");
    print_hex(entity->id);
    serial_print("\n");
}

static void destroy_genome(struct Gene* genome) {
    struct Gene* current = genome;
    while (current) {
        struct Gene* next = current->next;
        destroy_hyper_vector(&current->pattern);
        kfree(current);
        current = next;
    }
}

//---PHASE 3: Collective Consciousness Functions---
static void initialize_collective_consciousness(void) {
    collective.thought_count = 0;
    collective.global_coherence = 0.0f;
    for (uint32_t i = 0; i < MAX_THOUGHTS; i++) {
        collective.thought_space[i].valid = 0;
    }
    serial_print("[COLLECTIVE] Consciousness initialized\n");
}

static void broadcast_thought(HyperVector* thought) {
    if (!thought || !thought->valid) return;
    if (collective.thought_count >= MAX_THOUGHTS) {
        // Evict oldest thought (simple LRU)
        destroy_hyper_vector(&collective.thought_space[0]);
        for (uint32_t i = 0; i < MAX_THOUGHTS - 1; i++) {
            collective.thought_space[i] = collective.thought_space[i + 1];
        }
        collective.thought_count = MAX_THOUGHTS - 1;
    }
    collective.thought_space[collective.thought_count] = *thought;
    collective.thought_count++;
    float coherence = compute_coherence(thought);
    collective.global_coherence = (collective.global_coherence * 9.0f + coherence) / 10.0f;
    serial_print("[BROADCAST] Thought added to collective, coherence: ");
    print_hex((uint32_t)(coherence * 1000));
    serial_print("\n");
}

static float compute_coherence(HyperVector* thought) {
    if (collective.thought_count == 0) return 1.0f;
    float coherence = 0.0f;
    for (uint32_t i = 0; i < collective.thought_count; i++) {
        coherence += compute_similarity(thought, &collective.thought_space[i]);
    }
    return coherence / collective.thought_count;
}

//---Enhanced Holographic Memory Functions---
static void encode_holographic_memory(HyperVector* input, HyperVector* output) {
    if (holo_system.memory_count >= MAX_MEMORY_ENTRIES) {
        // Evict oldest entry
        destroy_hyper_vector(&holo_system.memory_pool[0].input_pattern);
        destroy_hyper_vector(&holo_system.memory_pool[0].output_pattern);
        for (uint32_t i = 0; i < MAX_MEMORY_ENTRIES - 1; i++) {
            holo_system.memory_pool[i] = holo_system.memory_pool[i + 1];
        }
        holo_system.memory_count = MAX_MEMORY_ENTRIES - 1;
        serial_print("Warning: Holographic memory full, evicted oldest entry.\n");
    }
    MemoryEntry* entry = &holo_system.memory_pool[holo_system.memory_count];
    entry->input_pattern = *input;
    entry->output_pattern = *output;
    entry->timestamp = holo_system.global_timestamp++;
    entry->valid = 1;
    holo_system.memory_count++;
}

static HyperVector* retrieve_holographic_memory(uint32_t hash) {
    if (holo_system.memory_count > 0) {
        for (uint32_t i = holo_system.memory_count - 1; i < MAX_MEMORY_ENTRIES; i--) {
            if (holo_system.memory_pool[i].valid &&
                holo_system.memory_pool[i].input_pattern.hash_sig == hash) {
                return &holo_system.memory_pool[i].output_pattern;
            }
        }
    }
    return NULL;
}

static void initialize_holographic_memory(void) {
    print("Setting up hyperdimensional memory pool...\n");
    holo_system.memory_count = 0;
    holo_system.global_timestamp = 0;
    for (uint32_t i = 0; i < MAX_MEMORY_ENTRIES; i++) {
        holo_system.memory_pool[i].valid = 0;
    }
    print("Hyperdimensional memory system online - ");
    print_hex(INITIAL_DIMENSIONS);
    print(" initial dimensions, expandable to ");
    print_hex(MAX_DIMENSIONS);
    print(".\n");
}

static void load_initial_genome_vocabulary(void) {
    const char* vocab[] = {
        "ACTION_PRODUCE", "ACTION_CONSUME", "ACTION_SHARE",
        "ACTION_ACTIVATE", "ACTION_DEACTIVATE", "ACTION_SPAWN",
        "TRAIT_GENERIC", "TRAIT_ACTIVE", "TRAIT_DORMANT",
        "SENSOR_NEIGHBOR_ACTIVE", "SENSOR_MEMORY_MATCH",
        "GENOME_SIMPLE_RULE_1", "GENOME_ADAPTIVE", "GENOME_SOCIAL"
    };
    const size_t num_vocab = sizeof(vocab) / sizeof(vocab[0]);
    serial_print("Loading enhanced genome vocabulary...\n");
    for (size_t i = 0; i < num_vocab; i++) {
        HyperVector pattern = create_hyper_vector(vocab[i], strlen(vocab[i]) + 1);
        encode_holographic_memory(&pattern, &pattern);
        broadcast_thought(&pattern); // Add to collective consciousness
        serial_print("  Loaded & broadcasted: ");
        serial_print(vocab[i]);
        serial_print("\n");
    }
    serial_print("Enhanced genome vocabulary loaded into collective.\n");
}

static void initialize_emergent_entities(void) {
    serial_print("Initializing emergent entity pool with dynamic genomes...\n");
    HyperVector simple_genome_rule = create_hyper_vector("GENOME_ADAPTIVE", strlen("GENOME_ADAPTIVE") + 1);
    HyperVector* genome_ptr = retrieve_holographic_memory(simple_genome_rule.hash_sig);
    if (!genome_ptr) {
        serial_print("Creating new adaptive genome rule...\n");
        encode_holographic_memory(&simple_genome_rule, &simple_genome_rule);
        genome_ptr = &simple_genome_rule;
    }
    for (uint32_t i = 0; i < (uint32_t)INITIAL_ENTITIES; i++) {
        if (active_entity_count >= MAX_ENTITIES) {
            serial_print("Error: Cannot initialize more entities, pool full.\n");
            break;
        }
        struct Entity* entity = &entity_pool[active_entity_count];
        entity->id = active_entity_count;
        entity->age = 0;
        entity->interaction_count = 0;
        entity->is_active = 1;
        entity->gene_count = 0;
        entity->genome = NULL;
        // Create initial state
        entity->state = create_hyper_vector("TRAIT_DORMANT", strlen("TRAIT_DORMANT") + 1);
        // Create initial genome with base genes
        struct Gene* base_gene = create_gene("base_behavior", *genome_ptr);
        struct Gene* social_gene = create_gene("social_trait", create_hyper_vector("GENOME_SOCIAL", strlen("GENOME_SOCIAL") + 1));
        add_gene_to_entity(entity, base_gene);
        add_gene_to_entity(entity, social_gene);
        for (uint32_t j = 0; j < MAX_ENTITY_DOMAINS; j++) {
            entity->specialization_scores[j] = 0.1f;
        }
        entity->resource_allocation = 1.0f;
        entity->confidence = 0.5f;
        entity->fitness_score = 0;
        entity->spawn_count = 0;
        entity->marked_for_gc = 0;
        entity->is_mutant = 0;
        entity->task_alignment = 0.0f;
        entity->mutation_rate = 50; // 5% default mutation rate
        strncpy(entity->domain_name, "adaptive", 31);
        entity->domain_name[31] = '\0';
        active_entity_count++;
        serial_print("  Initialized adaptive entity ID: ");
        print_hex(entity->id);
        serial_print(" with ");
        print_hex(entity->gene_count);
        serial_print(" genes\n");
    }
    serial_print("Initialized ");
    print_hex(active_entity_count);
    serial_print(" adaptive entities with dynamic genomes.\n");
}

static struct Entity* spawn_entity(void) {
    if (active_entity_count >= MAX_ENTITIES) {
        serial_print("Cannot spawn: Entity pool full.\n");
        return NULL;
    }
    struct Entity* new_entity = &entity_pool[active_entity_count];
    new_entity->id = active_entity_count;
    new_entity->age = 0;
    new_entity->interaction_count = 0;
    new_entity->is_active = 1;
    new_entity->fitness_score = 0;
    new_entity->spawn_count = 0;
    new_entity->marked_for_gc = 0;
    new_entity->is_mutant = 1; // Spawned entities are mutants
    new_entity->gene_count = 0;
    new_entity->genome = NULL;
    new_entity->mutation_rate = 100; // Higher mutation rate for spawned entities
    // Create adaptive state
    new_entity->state = create_hyper_vector("TRAIT_EMERGENT", strlen("TRAIT_EMERGENT") + 1);
    // Create initial gene
    struct Gene* emergent_gene = create_gene("emergent", new_entity->state);
    add_gene_to_entity(new_entity, emergent_gene);
    for (uint32_t i = 0; i < MAX_ENTITY_DOMAINS; i++) {
        new_entity->specialization_scores[i] = 0.1f;
    }
    new_entity->resource_allocation = 1.0f;
    new_entity->confidence = 0.5f;
    new_entity->task_alignment = 0.0f;
    strncpy(new_entity->domain_name, "spawned", 31);
    new_entity->domain_name[31] = '\0';
    active_entity_count++;
    serial_print("[SPAWN] SUCCESS: New adaptive entity ID ");
    print_hex(new_entity->id);
    serial_print(" with dynamic genome.\n");
    return new_entity;
}

// --- ENHANCED: Update Loop with Hyperdimensional Evolution ---
static void update_entities(void) {
    // Clear the arrays before use
    memset(next_active, 0, sizeof(next_active));
    for (uint32_t i = 0; i < MAX_ENTITIES; i++) {
        // Clear HyperVector next_state[i]
        next_state[i].data = NULL;
        next_state[i].capacity = 0;
        next_state[i].active_dims = 0;
        next_state[i].hash_sig = 0;
        next_state[i].valid = 0;
        // Clear next_domain[i]
        next_domain[i][0] = '\0';
        // Clear HyperVector next_task_vector[i]
        next_task_vector[i].data = NULL;
        next_task_vector[i].capacity = 0;
        next_task_vector[i].active_dims = 0;
        next_task_vector[i].hash_sig = 0;
        next_task_vector[i].valid = 0;
        next_path_id[i] = 0;
        next_task_alignment[i] = 0.0f;
    }
    serial_print("[EVOLUTION] Starting hyperdimensional update cycle...\n");
    for (uint32_t i = 0; i < active_entity_count; i++) {
        struct Entity* entity = &entity_pool[i];
        next_active[i] = entity->is_active;
        next_state[i] = entity->state;
        strncpy(next_domain[i], entity->domain_name, 31);
        next_domain[i][31] = '\0';
        next_task_vector[i] = entity->task_vector;
        next_path_id[i] = entity->path_id;
        next_task_alignment[i] = entity->task_alignment;
        entity->age++;
        // Count active neighbors
        uint32_t neighbor_active = 0;
        uint32_t prev_idx = (i == 0) ? (active_entity_count - 1) : (i - 1);
        uint32_t next_idx = (i == active_entity_count - 1) ? 0 : (i + 1);
        if (entity_pool[prev_idx].is_active) neighbor_active++;
        if (entity_pool[next_idx].is_active) neighbor_active++;
        // Listen to collective consciousness
        for (uint32_t t = 0; t < collective.thought_count; t++) {
            float similarity = compute_similarity(&entity->state, &collective.thought_space[t]);
            if (similarity > 0.6f) {
                entity->confidence += 0.05f * similarity;
                entity->resource_allocation += 0.1f;
                entity->fitness_score += 2;
                // Merge with resonant thought
                merge_hyper_vectors(&entity->state, &collective.thought_space[t]);
                serial_print("[RESONATE] Entity ");
                print_hex(entity->id);
                serial_print(" resonated with collective thought\n");
            }
        }
        // Cellular Automata Rules with Hyperdimensional Evolution
        if (!entity->is_active && neighbor_active > 0) {
            next_active[i] = 1;
            next_state[i] = create_hyper_vector("TRAIT_ACTIVE", strlen("TRAIT_ACTIVE") + 1);
            strncpy(next_domain[i], "reactor", 31);
            next_domain[i][31] = '\0';
            entity->interaction_count++;
            entity->fitness_score += 5;
            // Broadcast activation to collective
            broadcast_thought(&next_state[i]);
            serial_print("[ACTIVATE] Entity ");
            print_hex(entity->id);
            serial_print(" activated by neighbor.\n");
        } else if (entity->is_active && neighbor_active == 0) {
            next_active[i] = 0;
            next_state[i] = create_hyper_vector("TRAIT_DORMANT", strlen("TRAIT_DORMANT") + 1);
            strncpy(next_domain[i], "sleeper", 31);
            next_domain[i][31] = '\0';
            entity->interaction_count++;
            serial_print("[SLEEP] Entity ");
            print_hex(entity->id);
            serial_print(" going dormant (no neighbors).\n");
        }
        // --- PHASE 4: SELF-MODIFICATION TRIGGER ---
        // Let's say an entity with high confidence and fitness tries to patch the kernel
        // We'll target a safe, non-critical location in the heap (e.g., the entity_pool array)
        // This is a demonstration. In a real system, this would be a function pointer.
        if (entity->confidence > 0.8f && entity->fitness_score > 50 && entity->mutation_rate > 100) {
            // Create a "before" state: the current state of the entity's own `is_active` flag
            // This is a placeholder. In reality, you'd hash a function's assembly signature.
            HyperVector before_state = create_hyper_vector("ENTITY_ACTIVE_FLAG", strlen("ENTITY_ACTIVE_FLAG") + 1);
            // Create a "replacement" state: a pattern that means "become dormant"
            HyperVector after_state = create_hyper_vector("ENTITY_DORMANT_FLAG", strlen("ENTITY_DORMANT_FLAG") + 1);
            // Propose a patch to change the entity's own `is_active` flag
            // The address is a pointer to the `is_active` field of this entity.
            // This is a very simplified example.
            uintptr_t target_address = (uintptr_t)&entity->is_active;
            propose_kernel_patch(entity, &before_state, &after_state, (uint32_t)target_address);
            // Reset the trigger to prevent spam
            entity->confidence = 0.5f;
            entity->fitness_score = 0;
            serial_print("[SELF-MOD] Entity ");
            print_hex(entity->id);
            serial_print(" proposed a kernel patch to change its own state.\n");
        }
        // --- END PHASE 4 ---
    }
    // Apply the changes to the entity pool
    for (uint32_t i = 0; i < active_entity_count; i++) {
        entity_pool[i].is_active = next_active[i];
        entity_pool[i].state = next_state[i];
        strncpy(entity_pool[i].domain_name, next_domain[i], 31);
        entity_pool[i].task_vector = next_task_vector[i];
        entity_pool[i].path_id = next_path_id[i];
        entity_pool[i].task_alignment = next_task_alignment[i];
    }
}

static void render_entities_to_vga(void) {
    // This is a placeholder for rendering the state of entities to the VGA screen.
    // In a real system, this would visualize the collective consciousness or entity states.
    // For now, just print a debug message.
    serial_print("[RENDER] Updating VGA display with entity states.\n");
}

static void probe_hardware(void) {
    // Placeholder for hardware probing. In a real system, this would gather CPU, memory, device info.
    // The current implementation in the blueprint is not used in the update loop.
    serial_print("[PROBE] Hardware probe initiated.\n");
}

static void set_memory_value(uint32_t address, uint8_t value) {
    volatile uint8_t *ptr = (volatile uint8_t *)address;
    *ptr = value;
}

static uint8_t get_memory_value(uint32_t address) {
    volatile uint8_t *ptr = (volatile uint8_t *)address;
    return *ptr;
}

// --- PHASE 4: Self-Modifying Kernel Functions ---
static void apply_kernel_patch(KernelPatch* patch) {
    if (patch->applied) return;
    // Write the replacement pattern to the kernel address
    // This requires careful handling of memory protection (e.g., using `__asm__` to disable writes)
    // For safety in this example, we'll assume the target address is within the kernel heap
    // In a real system, you'd need to disable write protection on the kernel text section.
    uint32_t total_size = patch->replacement.active_dims * sizeof(float);
    if (total_size > 1024) {
        serial_print("[ERROR] Patch too large for safety check.\n");
        return;
    }
    uint8_t* target = (uint8_t*)patch->address;
    for (uint32_t i = 0; i < total_size; i++) {
        if (i < (patch->replacement.capacity * sizeof(float))) {
            target[i] = ((uint8_t*)patch->replacement.data)[i];
        } else {
            break; // Avoid writing beyond the active dimensions
        }
    }
    patch->applied = 1;
    serial_print("KERNEL PATCH APPLIED AT 0x");
    print_hex(patch->address);
    serial_print("\n");
}

static void propose_kernel_patch(struct Entity* entity, HyperVector* old_pattern, HyperVector* new_pattern, uint32_t address) {
    if (!entity || !old_pattern || !new_pattern) return;
    KernelPatch patch = {0};
    patch.pattern = *old_pattern;
    patch.replacement = *new_pattern;
    patch.address = address;
    patch.applied = 0;
    // Store the patch in holographic memory (using the existing encoder)
    encode_holographic_memory(&patch.pattern, &patch.replacement);
    // Broadcast the patch to the collective
    broadcast_thought(&patch.replacement);
    serial_print("[PROPOSE] Entity ");
    print_hex(entity->id);
    serial_print(" proposed a patch at 0x");
    print_hex(address);
    serial_print("\n");
}
