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

.global kprint_regs
kprint_regs:
	push 0(%esp) # eip
	pusha
	call __print_regs
	popa
	add $4, %esp
	ret

.global setjmp
setjmp:
	mov 4(%esp), %eax
	mov %edx, 0(%eax)
	mov %ebx, 4(%eax)
	mov %esp, 8(%eax)
	mov %ebp, 12(%eax)
	mov %esi, 16(%eax)
	mov %edi, 20(%eax)
	stmxcsr 24(%eax)
	fnstcw 28(%eax)
	movsd %xmm0, 32(%eax)
	movsd %xmm1, 40(%eax)
	movsd %xmm2, 48(%eax)
	movsd %xmm3, 56(%eax)
	movsd %xmm4, 64(%eax)
	movsd %xmm5, 72(%eax)
	movsd %xmm6, 80(%eax)
	movsd %xmm7, 88(%eax)
	mov 0(%esp), %ecx # eip
	mov %ecx, 96(%eax)
	xor %eax, %eax
	ret

.global longjmp
longjmp:
	mov 8(%esp), %eax
	mov 4(%esp), %ecx
	mov 0(%ecx), %edx
	mov 4(%ecx), %ebx
	mov 8(%ecx), %esp
	mov 12(%ecx), %ebp
	mov 16(%ecx), %esi
	mov 20(%ecx), %edi
	ldmxcsr 24(%ecx)
	fldcw 28(%ecx)
	movsd 32(%ecx), %xmm0
	movsd 40(%ecx), %xmm1
	movsd 48(%ecx), %xmm2
	movsd 56(%ecx), %xmm3
	movsd 64(%ecx), %xmm4
	movsd 72(%ecx), %xmm5
	movsd 80(%ecx), %xmm6
	movsd 88(%ecx), %xmm7
	push %eax
	mov 96(%ecx), %eax # eip
	mov %eax, 4(%esp)
	pop %eax
	xor %ecx, %ecx
	ret
