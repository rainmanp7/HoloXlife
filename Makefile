# Makefile
ASM = nasm
CC = gcc
CFLAGS = -m32 -c -ffreestanding -fno-pie -Wall -Wextra -std=c99 -nostdlib -fno-builtin
LDFLAGS = -m elf_i386 -T linker.ld --nmagic
QEMU = qemu-system-i386

all: emergeos.img

kernel_entry.o: kernel_entry.asm
	$(ASM) -f elf32 $< -o $@

holographic_kernel.o: holographic_kernel.c
	$(CC) $(CFLAGS) $< -o $@

kernel.bin: kernel_entry.o holographic_kernel.o
	ld $(LDFLAGS) -o kernel.elf $^
	objcopy -O binary kernel.elf kernel.bin

boot.bin: boot.asm kernel.bin
	@size=$$(stat -c%s kernel.bin); \
	sectors=$$(( (size + 511) / 512 )); \
	if [ $$sectors -lt 1 ]; then sectors=1; fi; \
	echo "Kernel size: $$size bytes → $$sectors sectors"; \
	$(ASM) -f bin -d HOLOGRAPHIC_KERNEL_SECTORS=$$sectors boot.asm -o boot.bin

emergeos.img: boot.bin kernel.bin
	dd if=/dev/zero of=emergeos.img bs=512 count=2880
	dd if=boot.bin of=emergeos.img conv=notrunc
	dd if=kernel.bin of=emergeos.img seek=1 conv=notrunc

run: emergeos.img
	$(QEMU) -fda emergeos.img

clean:
	rm -f *.bin *.o *.img *.elf

.PHONY: all clean run
