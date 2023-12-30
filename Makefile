CC=i686-elf-tools-windows/bin/i686-elf-gcc.exe
LD=i686-elf-tools-windows/bin/i686-elf-ld.exe
OBJDUMP=i686-elf-tools-windows/bin/i686-elf-objdump.exe

ifndef USB_DRIVE
USB_DRIVE=E:
endif

CFLAGS = -O2 -Wall -Wno-unused-function -Wno-unused-variable -ffreestanding -m32 -Iempty -DHL_OS -DHL_NO_THREADS -DLIBHL_EXPORTS -I$(HASHLINK_SRC)/src

RUNTIME = out/gc.o out/code.o out/module.o out/jit.o

STD = out/array.o out/buffer.o out/bytes.o out/cast.o out/error.o \
	out/fun.o out/maps.o out/obj.o out/random.o \
	out/string.o out/thread.o out/types.o out/ucs2.o

all: hl kernel

haxe:
	haxe app.hxml

hl:
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/gc.c -o out/gc.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/code.c -o out/code.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/module.c -o out/module.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/jit.c -o out/jit.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/std/array.c -o out/array.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/std/buffer.c -o out/buffer.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/std/bytes.c -o out/bytes.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/std/cast.c -o out/cast.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/std/error.c -o out/error.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/std/fun.c -o out/fun.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/std/maps.c -o out/maps.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/std/obj.c -o out/obj.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/std/random.c -o out/random.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/std/string.c -o out/string.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/std/thread.c -o out/thread.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/std/types.c -o out/types.o
	$(CC) $(CFLAGS) -c $(HASHLINK_SRC)/src/std/ucs2.c -o out/ucs2.o

dump:
	$(OBJDUMP) -x out/kernel.elf

kernel: haxe
	$(CC) $(CFLAGS) -O0 -c kernel.c -o out/kernel.o
	$(CC) $(CFLAGS) -c libc.c -o out/libc.o
	$(CC) $(CFLAGS) -c kernel_main.s -o out/kernel_main.o
	nasm tools/int32.asm -f elf -o out/int32.o
	$(CC) $(CFLAGS) -T kernel_linker.ld -o out/kernel.elf -nostdlib out/kernel_main.o out/kernel.o out/int32.o out/libc.o $(RUNTIME) $(STD)
	OBJDUMP=$(OBJDUMP) haxe -cp tools --run ElfExtract out/kernel.elf out/kernel.sym
	haxe -cp tools --run InjectFile -path out out/kernel.elf kernel.sym app.hl

# run the kernel using qemu boot loader that is capable of loading our kernel
run:
	qemu-system-i386 -machine type=pc-i440fx-3.1 -kernel out/kernel.elf


# see README.md
install_usb:
	cp tools/grub.cfg $(USB_DRIVE)/boot/grub
	cp out/kernel.elf $(USB_DRIVE)/boot

# boot qemu directly from your physical usb drive inserted in drive 2
# this needs to be run as administrator
# the drive number can be retreived on Windows by using the disc manager
run_usb:
	qemu-system-i386 -hda //./PhysicalDrive2

.PHONY: dump
