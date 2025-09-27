# Pure Ada HoloXlife OS Makefile - NO C CODE
ASM = nasm
GNAT = gnat
GNATBIND = gnatbind
GNATLINK = gnatlink

# Pure Ada bare-metal flags
ADAFLAGS = -gnat2012 -gnatwa -gnatwe -gnatp -O2 \
           -m32 -ffreestanding -nostdlib -nodefaultlibs \
           -fno-stack-protector -static

# Linker flags for bare-metal Ada
LDFLAGS = -m elf_i386 -T linker.ld --nmagic -nostdlib -static

QEMU = qemu-system-i386

all: emergeos.img

# Create Ada configuration
gnat.adc:
	@echo "pragma Restrictions (No_Run_Time);" > gnat.adc
	@echo "pragma Restrictions (No_Exceptions);" >> gnat.adc  
	@echo "pragma Restrictions (No_Implicit_Heap_Allocations);" >> gnat.adc
	@echo "pragma Restrictions (No_Tasking);" >> gnat.adc
	@echo "pragma Restrictions (No_Protected_Types);" >> gnat.adc

# Assemble kernel entry point
kernel_entry.o: kernel_entry.asm
	$(ASM) -f elf32 kernel_entry.asm -o kernel_entry.o

# Compile Pure Ada kernel
emergeos.o: emergeos.adb system.ads gnat.adc
	$(GNAT) compile $(ADAFLAGS) -c emergeos.adb
	$(GNAT) compile $(ADAFLAGS) -c system.ads

# Link Pure Ada OS kernel
kernel.bin: kernel_entry.o emergeos.o
	ld $(LDFLAGS) -o kernel.elf kernel_entry.o emergeos.o
	objcopy -O binary kernel.elf kernel.bin

# Create bootloader with proper kernel size
boot.bin: boot.asm kernel.bin
	@SECTORS=$$(( ($$(wc -c < kernel.bin) + 511) / 512 )); \
	echo "Building Pure Ada OS with $$SECTORS kernel sectors"; \
	$(ASM) -f bin -d HOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o boot.bin

# Assemble final OS image
emergeos.img: boot.bin kernel.bin
	@echo "Creating HoloXlife Pure Ada OS disk image..."
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=boot.bin of=$@ conv=notrunc
	dd if=kernel.bin of=$@ seek=1 conv=notrunc
	@echo "HoloXlife OS (Pure Ada) image created: emergeos.img"

# Run Pure Ada OS in QEMU
run: emergeos.img
	@echo "Booting HoloXlife Pure Ada Operating System..."
	$(QEMU) -fda $< -serial stdio -no-reboot -no-shutdown

# Debug run with more verbose output
debug: emergeos.img 
	$(QEMU) -fda $< -serial stdio -d int -no-reboot

# Clean build artifacts
clean:
	rm -f *.bin *.o *.img *.elf *.ali gnat.adc
	@echo "Pure Ada OS build cleaned"

# Install dependencies (Ubuntu/Debian)
install-deps:
	@echo "Installing Pure Ada OS build dependencies..."
	sudo apt update
	sudo apt install -y gnat-10 nasm qemu-system-x86 build-essential
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
	@echo "Build System: GNAT + NASM"
	@echo "========================================="

.PHONY: all clean run debug install-deps info
