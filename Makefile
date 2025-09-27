# Makefile for EmergeOS Ada Kernel
ASM = nasm
GNATMAKE = gnatmake
GPRBUILD = gprbuild
LD = ld
OBJCOPY = objcopy
QEMU = qemu-system-i386

# Flags
ASMFLAGS = -f elf32
LDFLAGS = -m elf_i386 -T linker.ld --nmagic
GNATFLAGS = -gnat2012 -gnatwa -gnatwe -fno-builtin -nostdlib -ffreestanding -m32 -O2 -gnatp -fno-stack-protector

.PHONY: all clean run

all: emergeos.img

# Compile Ada kernel to object file
emergeos.o: emergeos.adb emergeos.gpr
	@echo "Compiling Ada kernel..."
	$(GNATMAKE) -c $(GNATFLAGS) emergeos.adb -o emergeos.o
	@echo "Ada kernel compiled successfully"

# Assemble kernel entry point
kernel_entry.o: kernel_entry.asm
	@echo "Assembling kernel entry..."
	$(ASM) $(ASMFLAGS) kernel_entry.asm -o kernel_entry.o

# Link kernel
kernel.bin: kernel_entry.o emergeos.o linker.ld
	@echo "Linking kernel..."
	$(LD) $(LDFLAGS) -o kernel.elf kernel_entry.o emergeos.o -lgcc
	$(OBJCOPY) -O binary kernel.elf kernel.bin
	@echo "Kernel linked: $$(stat -c%s kernel.bin) bytes"

# Assemble bootloader with dynamic sector calculation
boot.bin: boot.asm kernel.bin
	@SECTORS=$$(( ($$(wc -c < kernel.bin) + 511) / 512 )); \
	echo "Building bootloader for $$SECTORS kernel sectors..."; \
	$(ASM) -f bin -d HOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o boot.bin
	@echo "Bootloader built: $$(stat -c%s boot.bin) bytes"

# Create disk image
emergeos.img: boot.bin kernel.bin
	@echo "Creating disk image..."
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	dd if=boot.bin of=$@ conv=notrunc 2>/dev/null
	dd if=kernel.bin of=$@ seek=1 conv=notrunc 2>/dev/null
	@echo "✅ EmergeOS disk image created: $$(stat -c%s $@) bytes"

# Run in QEMU
run: emergeos.img
	@echo "Starting EmergeOS in QEMU..."
	$(QEMU) -fda emergeos.img

# Run with debugging
debug: emergeos.img
	@echo "Starting EmergeOS in QEMU with debugging..."
	$(QEMU) -fda emergeos.img -serial stdio -d cpu_reset

# Clean build artifacts
clean:
	@echo "Cleaning build files..."
	rm -f *.o *.bin *.elf *.img *.ali
	@echo "Clean complete"

# Help target
help:
	@echo "EmergeOS Ada Build System"
	@echo "========================="
	@echo "Targets:"
	@echo "  all     - Build complete EmergeOS image"
	@echo "  run     - Build and run in QEMU"
	@echo "  debug   - Run with QEMU debugging"
	@echo "  clean   - Remove all build artifacts"
	@echo "  help    - Show this help"
