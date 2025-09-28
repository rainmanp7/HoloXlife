# Pure Ada HoloXlife OS Makefile - NO RUNTIME DEPENDENCIES
ASM = nasm
GCC = gcc-10
# Use GCC directly for Ada compilation (bypass gnatmake)
ADAFLAGS = -x ada -gnat2012 -gnatwa -gnatwo -gnatp -O2 \
           -m32 -nostdlib -nodefaultlibs \
           -fno-stack-protector -static -c \
           -gnatec=gnat.adc
# Linker flags for bare-metal Ada
LDFLAGS = -m elf_i386 -T linker.ld --nmagic -nostdlib -static
BOCHS = bochs
BOCHS_CONFIG = bochsrc.txt

all: emergeos.img

# Create Ada configuration file (restricts runtime features)
gnat.adc:
	@echo "pragma Restrictions (No_Exceptions);" > gnat.adc
	@echo "pragma Restrictions (No_Implicit_Heap_Allocations);" >> gnat.adc
	@echo "pragma Restrictions (No_Tasking);" >> gnat.adc
	@echo "pragma Restrictions (No_Protected_Types);" >> gnat.adc
	@echo "pragma Restrictions (No_Finalization);" >> gnat.adc

# Compile bootloader in Ada
boot.o: boot.adb gnat.adc
	$(GCC) $(ADAFLAGS) boot.adb -o boot.o

# Compile Pure Ada kernel using GCC directly (no gnatmake)
emergeos.o: emergeos.adb gnat.adc
	$(GCC) $(ADAFLAGS) emergeos.adb -o emergeos.o

# Link Pure Ada OS kernel and bootloader
kernel.bin: boot.o emergeos.o
	ld $(LDFLAGS) -o kernel.elf boot.o emergeos.o
	objcopy -O binary kernel.elf kernel.bin

# If you have boot.asm and want to build boot.bin from it, uncomment below
# boot.bin: boot.asm kernel.bin
#	@SECTORS=$$(( ($$(wc -c < kernel.bin) + 511) / 512 )); \
#	echo "Building Pure Ada OS with $$SECTORS kernel sectors"; \
#	$(ASM) -f bin -d HOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o boot.bin

# Assemble final OS image (using boot.o + kernel)
emergeos.img: kernel.bin
	@echo "Creating HoloXlife Pure Ada OS disk image..."
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=kernel.bin of=$@ conv=notrunc
	@echo "HoloXlife OS (Pure Ada) image created: emergeos.img"

# Run Pure Ada OS in Bochs
run: emergeos.img
	@echo "Booting HoloXlife Pure Ada Operating System..."
	$(BOCHS) -f $(BOCHS_CONFIG)

# Debug run with more verbose output
debug: emergeos.img
	@echo "Debugging HoloXlife Pure Ada Operating System..."
	$(BOCHS) -f $(BOCHS_CONFIG) -dbgui

# Clean build artifacts
clean:
	rm -f *.bin *.o *.img *.elf *.ali gnat.adc
	@echo "Pure Ada OS build cleaned"

# Install dependencies (Ubuntu/Debian)
install-deps:
	@echo "Installing Pure Ada OS build dependencies..."
	sudo apt update
	sudo apt install -y gcc-10 gcc-10-multilib nasm bochs bochs-x11 build-essential
	@echo "Dependencies installed - ready for Pure Ada OS development!"

# Show build info
info:
	@echo "========================================="
	@echo "HoloXlife Pure Ada Operating System"
	@echo "========================================="
	@echo "Language: 100% Ada (No C code)"
	@echo "Architecture: i686 (32-bit x86)"
	@echo "Memory: Holographic 512x512 matrix"
	@echo "Features: Entity-based architecture"
	@echo "Build System: GCC + NASM (No GNAT runtime)"
	@echo "========================================="

.PHONY: all clean run debug install-deps info
