ASM = nasm
CC = gcc
CFLAGS = -m32 -c -ffreestanding -fno-pie -Wall -Wextra -std=c99 -nostdlib -fno-builtin
ADAFLAGS = -c -x ada -gnat2012 -gnatwa -gnatwe -m32 -O2 \
           -ffreestanding -nostdlib -fno-builtin -fno-stack-protector
LDFLAGS = -m elf_i386 -T linker.ld --nmagic
QEMU = qemu-system-i386

# Default target
all: emergeos.img

# Assembly entry point
kernel_entry.o: kernel_entry.asm
	$(ASM) -f elf32 kernel_entry.asm -o kernel_entry.o

# Ada kernel and minimal RTS
emergeos.o: emergeos.adb system.ads s-lastch.ads s-lastch.adb s-memory.ads s-memory.adb
	$(CC) $(ADAFLAGS) emergeos.adb
	$(CC) $(ADAFLAGS) s-lastch.adb
	$(CC) $(ADAFLAGS) s-memory.adb

# Link kernel (Ada + ASM entry)
kernel.bin: kernel_entry.o emergeos.o
	ld $(LDFLAGS) -o kernel.elf $^
	objcopy -O binary kernel.elf kernel.bin

# Boot sector (unchanged)
boot.bin: boot.asm kernel.bin
	@SECTORS=$$(( ($$(wc -c < kernel.bin) + 511) / 512 )); \
	echo "Building boot.bin with $$SECTORS sectors"; \
	$(ASM) -f bin -d HOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o boot.bin

# Floppy image
emergeos.img: boot.bin kernel.bin
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=boot.bin of=$@ conv=notrunc
	dd if=kernel.bin of=$@ seek=1 conv=notrunc

# Run in QEMU
run: emergeos.img
	$(QEMU) -fda $@

# Clean
clean:
	rm -f *.bin *.o *.img *.elf *.ali

.PHONY: all clean run
