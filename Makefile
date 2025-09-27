ASM = nasm
CC = gcc
ADAFLAGS = -c -x ada -gnat2012 -gnatwa -gnatwe -m32 -O2 -gnatp -fno-stack-protector
LDFLAGS = -m elf_i386 -T linker.ld --nmagic
QEMU = qemu-system-i386

all: emergeos.img

kernel_entry.o: kernel_entry.asm
	$(ASM) -f elf32 kernel_entry.asm -o kernel_entry.o

emergeos.o: emergeos.adb system.ads s-lastch.ads s-lastch.adb s-memory.ads s-memory.adb
	$(CC) $(ADAFLAGS) emergeos.adb
	$(CC) $(ADAFLAGS) s-lastch.adb
	$(CC) $(ADAFLAGS) s-memory.adb

kernel.bin: kernel_entry.o emergeos.o
	ld $(LDFLAGS) -o kernel.elf $^
	objcopy -O binary kernel.elf kernel.bin

boot.bin: boot.asm kernel.bin
	@SECTORS=$$(( ($$(wc -c < kernel.bin) + 511) / 512 )); \
	echo "Building boot.bin with $$SECTORS sectors"; \
	$(ASM) -f bin -d HOLOGRAPHIC_KERNEL_SECTORS=$$SECTORS boot.asm -o boot.bin

emergeos.img: boot.bin kernel.bin
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=boot.bin of=$@ conv=notrunc
	dd if=kernel.bin of=$@ seek=1 conv=notrunc

run: emergeos.img
	$(QEMU) -fda $@

clean:
	rm -f *.bin *.o *.img *.elf *.ali

.PHONY: all clean run
