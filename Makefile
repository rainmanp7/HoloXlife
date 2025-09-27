ASM = nasm
CC = gcc
CFLAGS = -m32 -c -ffreestanding -fno-pie -Wall -Wextra -std=c99 -nostdlib -fno-builtin
LDFLAGS = -m elf_i386 -T linker.ld --nmagic
QEMU = qemu-system-i386

all: emergeos.img

kernel_entry.o: kernel_entry.asm
	nasm -f elf32 kernel_entry.asm -o kernel_entry.o

holographic_kernel.o: holographic_kernel.c
	gcc $(CFLAGS) holographic_kernel.c -o holographic_kernel.o

kernel.bin: kernel_entry.o holographic_kernel.o
	ld $(LDFLAGS) -o kernel.elf $^
	objcopy -O binary kernel.elf kernel.bin

boot.bin: boot.asm kernel.bin
	@SECTORS=$$(( ($$(wc -c < kernel.bin) + 511) / 512 )); \
	echo "Building boot.bin with $$SECTORS sectors"; \
	nasm -f bin -d HOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o boot.bin

emergeos.img: boot.bin kernel.bin
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=boot.bin of=$@ conv=notrunc
	dd if=kernel.bin of=$@ seek=1 conv=notrunc

run: emergeos.img
	$(QEMU) -fda $@

clean:
	rm -f *.bin *.o *.img *.elf

.PHONY: all clean run
