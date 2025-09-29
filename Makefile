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
	@echo "pragma Restrictions (No_Secondary_Stack);" >> gnat.adc

# Compile bootloader in Ada
boot.o: boot.adb gnat.adc
	$(GCC) $(ADAFLAGS) boot.adb -o boot.o

# Compile Pure Ada kernel using GCC directly (no gnatmake)
emergeos.o: emergeos.adb emergeos.ads gnat.adc
	$(GCC) $(ADAFLAGS) emergeos.adb -o emergeos.o

# Link Pure Ada OS kernel 
kernel.bin: boot.o emergeos.o linker.ld
	ld $(LDFLAGS) -o kernel.elf boot.o emergeos.o
	objcopy -O binary kernel.elf kernel.bin

# Build bootloader from assembly
boot.bin: boot.asm kernel.bin
	@SECTORS=$$(( ($$(wc -c < kernel.bin) + 511) / 512 )); \
	echo "Building Pure Ada OS with $$SECTORS kernel sectors"; \
	$(ASM) -f bin -D HOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o boot.bin

# Create final OS image
emergeos.img: boot.bin kernel.bin
	@echo "Creating HoloXlife Pure Ada OS disk image..."
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	dd if=boot.bin of=$@ conv=notrunc 2>/dev/null
	dd if=kernel.bin of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null
	@echo "HoloXlife OS (Pure Ada) image created: emergeos.img"

# Run Pure Ada OS in Bochs
run: emergeos.img
	@echo "Booting HoloXlife Pure Ada Operating System..."
	$(BOCHS) -f $(BOCHS_CONFIG)

# Clean build artifacts
clean:
	rm -f *.bin *.o *.img *.elf *.ali gnat.adc
	@echo "Pure Ada OS build cleaned"

.PHONY: all clean run
