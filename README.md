# HL-OS

A toy operating system for HashLink VM

This allows you to create a self-contained bootable image binary that includes:
  - a boot loader (`boot.asm`)
  - a very small kernel (`kernel.c`)
  - the kernel symbol table extracted from its ELF (see `ElfExtract.hx`)
  - the [HashLink VM](https://hashlink.haxe.org)
  - a minimal libc required to run the HLVM (`lib.c`)
  - your application code compiled into HL bytecode (`App.hx` compiled into `out/app.hl` with [Haxe](https://haxe.org))

The boot sequence is the following:
  - BootLoader:
    - read the device data
    - map the kernel code, symbold and VM bytecode into memory
    - enter into protected mode
    - call the kernel
  - Kernel:
    - clear the screen
    - init the symbols table
    - load the HLVM bytecode
    - run it (the HLVM will translate it to machine code first)
  - Congratulations ! You are now running your Haxe App in Kernel mode

## Compiling and Running

In order to compile HL-OS, you need GCC/LD/NASM/OBJDUMP toolchain.
On Windows and OSX you need a cross compiler version capable of outputing ELF x86 code.

This can be downloaded from [here](https://github.com/lordmilko/i686-elf-tools/releases)

Look at `Makefile` for more details.

In order to run the HLOS image, you can use [QEmu](https://www.qemu.org/), then simply `make run`

Please note that atm the HLOS image is only working as a 1.44MB Floppy Drive.
I might later look into allowing USB Boot drive compatibility and UEFI boot, but this is more complex to manage.
