[org 0x7c00]
[bits 16]

STACK_POSITION equ 0x0500
KERNEL_POSITION equ 0x8000

; ------------- BOOT ----------------

mov sp, STACK_POSITION
mov bx, WELCOME_MSG
call bios_print
call bios_print_nl
call load_kernel
call enter_protected_mode
jmp $

; ------------- 16 bit BIOS funs ----------------

bios_print:
    pusha
start:
    mov al, [bx]
    cmp al, 0
    je done
    mov ah, 0x0e
    int 0x10
    add bx, 1
    jmp start
done:
    popa
    ret

bios_print_nl:
    pusha
    mov ah, 0x0e
    mov al, 0x0a
    int 0x10
    mov al, 0x0d
	int 0x10
    popa
    ret

debug:
	push bx
	mov bx, DEBUG_TXT
	call bios_print
	call bios_print_nl
	pop bx
	ret

disk_load:
		pusha

		mov cl, 2 ; start from sector 2 after our boot
		mov dh, 0 ; head
		mov ch, 0 ; cylinder

  	loop:

		push ax
		mov ah, 0x02 ; 'read'
		mov al, 0x01 ; number of sectors
		int 0x13     ; read data into [es:bx]
		jc disk_error
		cmp al, 0x01   ; result
		jne disk_error
		pop ax

		sub ax, 1
		cmp ax, 0
		je end
		add cl, 1
		cmp cl, 37
		jne next
		mov cl, 1
		add dh, 1
		cmp dh, 2
		jne next
		mov dh, 0
		add ch, 1
	next:
		mov bx, es
		add bx, 32 ; 512 bytes in extended mode
		mov es, bx
		mov bx, 0
		jmp loop
	disk_error:
		mov bx, DISC_ERROR_MSG
		call bios_print
		call bios_print_nl
		jmp $
	end:
	    popa
    	ret

; ------------- GDT ----------------

gdt_start:
	dd 0x0 ; 4 byte
    dd 0x0 ; 4 byte
gdt_code:
    dw 0xffff    ; segment length, bits 0-15
    dw 0x0       ; segment base, bits 0-15
    db 0x0       ; segment base, bits 16-23
    db 10011010b ; flags (8 bits)
    db 11001111b ; flags (4 bits) + segment length, bits 16-19
    db 0x0       ; segment base, bits 24-31
gdt_data:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0
gdt_end:
gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; size (16 bit), always one less of its true size
    dd gdt_start ; address (32 bit)

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; ------------- PROTECTED MODE ----------------

[bits 16]
load_kernel:
	mov ax, KERNEL_POSITION
	shr ax, 4
	mov es, ax
	mov bx, 0
	mov ax, 960 ; that's the maximum of sectors than can fit in our 0x8000 - 0x80000 BIOS memory section
	call disk_load
	ret

enter_protected_mode:
	cli
	lgdt [gdt_descriptor]
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp CODE_SEG:init_protected_mode

[bits 32]
init_protected_mode:
	mov ax, DATA_SEG
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ebp, 0x90000
	mov esp, ebp
	call KERNEL_POSITION
	jmp $

; ------------- DATA ----------------

WELCOME_MSG:
	db 'Starting HL-OS...', 0

DEBUG_TXT:
	db '#D#', 0

DL_SECTOR:
	db 0
DL_CYLINDER:
	db 0
DL_HEAD
	db 0

DISC_ERROR_MSG:
	db '*** DISC ERROR ***', 0

DISC_ERROR_MSG2:
	db '*** DISC ERROR (2) ***', 0

; padding and magic number
times 510 - ($-$$) db 0
dw 0xaa55
