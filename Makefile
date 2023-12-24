CC=i686-elf-tools-windows/bin/i686-elf-gcc.exe
LD=i686-elf-tools-windows/bin/i686-elf-ld.exe
OBJDUMP=i686-elf-tools-windows/bin/i686-elf-objdump.exe

CFLAGS = -Wall -Wno-unused-function -Wno-unused-variable -ffreestanding -m32 -Iempty -DHL_OS -DHL_NO_THREADS -DLIBHL_EXPORTS -I$(HASHLINK_SRC)/src

RUNTIME = out/gc.o out/code.o out/module.o out/jit.o

STD = out/array.o out/buffer.o out/bytes.o out/cast.o out/error.o \
	out/fun.o out/maps.o out/obj.o out/random.o \
	out/string.o out/thread.o out/types.o out/ucs2.o

all: boot

boot:
	nasm -fbin boot.asm -o out/boot.bin

kernel: hl haxe
	$(CC) $(CFLAGS) -c kernel.c -o out/kernel.o
	$(CC) $(CFLAGS) -c libc.c -o out/libc.o
	nasm kernel_main.asm -f elf -o out/kernel_main.o
	$(LD) -o out/kernel.bin -Ttext 0x8000 out/kernel_main.o out/kernel.o out/libc.o $(RUNTIME) $(STD) --oformat binary
	$(LD) -o out/kernel.elf -Ttext 0x8000 out/kernel_main.o out/kernel.o out/libc.o $(RUNTIME) $(STD)

haxe:
	haxe -hl out/app.hl -main App -dce full

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

symbols:
	OBJDUMP=$(OBJDUMP) haxe --run ElfExtract out/kernel.elf out/kernel.sym

image: kernel symbols boot
	cat out/boot.bin out/kernel.bin >image.bin

run:
	qemu-system-i386 -fda image.bin
