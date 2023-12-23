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

disk_load:
    pusha
    push dx
    mov ah, 0x02 ; ah <- int 0x13 function. 0x02 = 'read'
    mov al, dh   ; al <- number of sectors to read (0x01 .. 0x80)
    mov cl, 0x02 ; cl <- sector (0x01 .. 0x11)
                 ; 0x01 is our boot sector, 0x02 is the first 'available' sector
    mov ch, 0x00 ; ch <- cylinder (0x0 .. 0x3FF, upper 2 bits in 'cl')
    ; dl <- drive number. Our caller sets it as a parameter and gets it from BIOS
    ; (0 = floppy, 1 = floppy2, 0x80 = hdd, 0x81 = hdd2)
    mov dh, 0x00 ; dh <- head number (0x0 .. 0xF)
    ; [es:bx] <- pointer to buffer where the data will be stored
    ; caller sets it up for us, and it is actually the standard location for int 13h
    int 0x13      ; BIOS interrupt
    jc disk_error ; if error (stored in the carry bit)
    pop dx
    cmp al, dh    ; BIOS also sets 'al' to the # of sectors read. Compare it.
    jne disk_error2
    popa
    ret

disk_error:
	mov bx, DISC_ERROR_MSG
	call bios_print
	call bios_print_nl
	jmp $

disk_error2:
	mov bx, DISC_ERROR_MSG2
	call bios_print
	call bios_print_nl
	jmp $

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
	mov dh, 64
	mov dl, [BOOT_DRIVE]
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

BOOT_DRIVE:
	db 0

WELCOME_MSG:
	db 'Starting HL-OS...', 0

DISC_ERROR_MSG:
	db '*** DISC ERROR ***', 0

DISC_ERROR_MSG2:
	db '*** DISC ERROR (2) ***', 0

; padding and magic number
times 510 - ($-$$) db 0
dw 0xaa55
