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
	call enable_sse2
	call kmain
	cli
1:	hlt
	jmp 1b

enable_sse2:
	mov $1, %eax
	cpuid
	test $(1<<26), %edx
	jnz sse_enable
	push $NO_SSE2_ERROR
	call kpanic
sse_enable:
	mov %cr0, %eax
	and $0xFFFB, %ax
	or $2, %ax
	mov %eax, %cr0
	mov %cr4, %eax
	or $(3 << 9), %ax
	mov %eax, %cr4
	ret
NO_SSE2_ERROR:
	.ascii "No SSE2 Available"
	.byte 0


