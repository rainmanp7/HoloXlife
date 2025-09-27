# Makefile
ASM = nasm
CC = gcc
CFLAGS = -m32 -c -ffreestanding -fno-pie -Wall -Wextra -std=c99 -nostdlib -fno-builtin
LDFLAGS = -m elf_i386 -T linker.ld --nmagic
QEMU = qemu-system-i386

# Always build kernel first, then compute sectors
kernel.bin: kernel_entry.o holographic_kernel.o
	ld $(LDFLAGS) -o kernel.elf $^
	objcopy -O binary kernel.elf $@
	@echo "Kernel size: $$(stat -c%s $@) bytes"

boot.bin: boot.asm kernel.bin
	@sectors=$$(( ($$(stat -c%s kernel.bin) + 511) / 512 )); \
	if [ $$sectors -lt 1 ]; then sectors=1; fi; \
	echo "Loading $$sectors sectors"; \
	$(ASM) -f bin -d HOLOGRAPHIC_KERNEL_SECTORS=$$sectors $< -o $@

emergeos.img: boot.bin kernel.bin
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=boot.bin of=$@ conv=notrunc
	dd if=kernel.bin of=$@ seek=1 conv=notrunc

kernel_entry.o: kernel_entry.asm
	$(ASM) -f elf32 $< -o $@

holographic_kernel.o: holographic_kernel.c
	$(CC) $(CFLAGS) $< -o $@

all: emergeos.img

run: emergeos.img
	$(QEMU) -fda $@

clean:
	rm -f *.bin *.o *.img *.elf

.PHONY: all clean run
