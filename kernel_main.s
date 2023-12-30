.set FLAGS,    2
.set MAGIC,    0x1BADB002
.set CHECKSUM, -(MAGIC + FLAGS)

.set FILES_MAGIC,    	0xBAD0CAFE
.set FILES_MAX_SIZE, 	(128 << 10)

.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

.section .files
.global _FILES_DATA
_FILES_DATA:
	.align 1
	.ascii "KFILES_BEGIN"
	.long FILES_MAX_SIZE
	.fill (FILES_MAX_SIZE - (. - _FILES_DATA) - 4), 1, 0
	.long FILES_MAGIC

.section .bss
.align 16
stack_bottom:
.skip 0x4000 # 16 KB
stack_top:

.section .text
.global _start
.type _start, @function
_start:
	mov $stack_top, %esp
	call kmain
	cli
1:	hlt
	jmp 1b

.size _start, . - _start
