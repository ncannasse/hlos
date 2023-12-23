#include <hlmodule.h>

static unsigned int *HL_CODE_ADDR = (unsigned int *)0x48000;

static unsigned char port_byte_in(unsigned short port) {
    unsigned char result;
    __asm__("in %%dx, %%al" : "=a" (result) : "d" (port));
    return result;
}

static void port_byte_out(unsigned short port, unsigned char data) {
    __asm__("out %%al, %%dx" : : "a" (data), "d" (port));
}

static unsigned short port_word_in(unsigned short port) {
    unsigned short result;
    __asm__("in %%dx, %%ax" : "=a" (result) : "d" (port));
    return result;
}

static void port_word_out(unsigned short port, unsigned short data) {
    __asm__("out %%ax, %%dx" : : "a" (data), "d" (port));
}

#define VGA_OP 0x3d4
#define VGA_DATA 0x3d5
#define VGA_CURSOR_POS_LOW 15
#define VGA_CURSOR_POS_HIGH 14
#define VGA_MEM ((char*)0xB8000)
#define VGA_ROWS 25
#define VGA_COLS 80

static int vga_cursor = 0;

void cls() {
	int i;
	for(i=0;i<VGA_COLS*VGA_ROWS;i++) {
		VGA_MEM[i<<1] = ' ';
		VGA_MEM[(i<<1)+1] = 0x7;
	}
}

int get_cursor() {
    port_byte_out(VGA_OP, VGA_CURSOR_POS_HIGH);
    int position = port_byte_in(VGA_DATA);
    position = position << 8;
    port_byte_out(VGA_OP, VGA_CURSOR_POS_LOW);
    position += port_byte_in(VGA_DATA);
    return position;
}

void set_cursor( int position ) {
    port_byte_out(VGA_OP, VGA_CURSOR_POS_HIGH);
    port_byte_out(VGA_DATA, position >> 8);
    port_byte_out(VGA_OP, VGA_CURSOR_POS_LOW);
    port_byte_out(VGA_DATA, position & 0xFF);
}

void kprint_char( char c ) {
	if( c == '\n' ) {
		kprint_char(' ');
		while( vga_cursor % VGA_COLS != 0 )
			kprint_char(' ');
		return;
	}
	if( vga_cursor == VGA_COLS * VGA_ROWS ) {
		// scroll line
		int i;
		memcpy(VGA_MEM,VGA_MEM + VGA_COLS*2, (VGA_COLS * (VGA_ROWS - 1)) * 2);
		for(i=0;i<VGA_COLS;i++)
			VGA_MEM[((VGA_ROWS - 1) * VGA_COLS + i) * 2] = ' ';
		vga_cursor -= VGA_COLS;
	}
	VGA_MEM[(vga_cursor++) << 1] = c;
	set_cursor(vga_cursor);
}

void kprint( const char *str ) {
	while( *str )
		kprint_char(*str++);
}

void kerror( const char *str ) {
	kprint("**** KERNEL ERROR (");
	kprint(str);
	kprint(") ***\n");
}

void kpanic( const char *str ) {
	kprint("*** KERNEL PANIC (");
	kprint(str);
	kprint(") ***");
	while( 1 ) {
	}
}

typedef struct {
	hl_code *code;
	hl_module *m;
	vdynamic *ret;
	int file_time;
} main_context;

int hl_main() {
	static vclosure cl;
	main_context ctx;
	bool isExc = false;
	char *error_msg = NULL;
	if( *HL_CODE_ADDR != 0xBAD0CAFE )
		kpanic("Invalid code start");
	int code_size = HL_CODE_ADDR[1];
	hl_global_init();
	hl_register_thread(&ctx);
	ctx.code = hl_code_read((unsigned char*)(HL_CODE_ADDR + 2), code_size, &error_msg);
	if( ctx.code == NULL ) {
		if( error_msg ) kerror(error_msg);
		return 1;
	}
	/*
	ctx.m = hl_module_alloc(ctx.code);
	if( ctx.m == NULL )
		return 2;
	if( !hl_module_init(ctx.m,false) )
		return 3;
	hl_code_free(ctx.code);
	cl.t = ctx.code->functions[ctx.m->functions_indexes[ctx.m->code->entrypoint]].type;
	cl.fun = ctx.m->functions_ptrs[ctx.m->code->entrypoint];
	cl.hasValue = 0;
	ctx.ret = hl_dyn_call_safe(&cl,NULL,0,&isExc);
	if( isExc ) {
		varray *a = hl_exception_stack();
		int i;
		uprintf(USTR("Uncaught exception: %s\n"), hl_to_string(ctx.ret));
		for(i=0;i<a->size;i++)
			uprintf(USTR("Called from %s\n"), hl_aptr(a,uchar*)[i]);
		hl_global_free();
		return 1;
	}
	hl_module_free(ctx.m);
	*/
	hl_free(&ctx.code->alloc);
	hl_global_free();
	return 0;
}

void kmain() {
	cls();
	set_cursor(0);
	kprint("Starting HLOS...\n");
	int ret = hl_main();
	printf("**** EXIT with code %d ****\n", ret);
	while( true ) {}
}