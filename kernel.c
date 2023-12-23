#include <hlmodule.h>

#define HL_CODE_ADDR 0x1000
#define HL_CODE_SIZE 0

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
	VGA_MEM[(vga_cursor++) << 1] = c;
	set_cursor(vga_cursor);
}

void kprint( const char *str ) {
	while( *str )
		kprint_char(*str++);
}

void kpanic( const char *str ) {
	kprint(str);
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
	/*
	hl_global_init();
	hl_register_thread(&ctx);
	ctx.code = hl_code_read((unsigned char*)HL_CODE_ADDR, HL_CODE_SIZE, &error_msg);
	if( ctx.code == NULL ) {
		if( error_msg ) {
			kernel_print(error_msg);
			kernel_print("\n");
		}
		return 1;
	}
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
	hl_free(&ctx.code->alloc);
	hl_global_free();*/
	return 0;
}

void kmain() {
	cls();
	set_cursor(0);
	kprint("Start...");
	//int ret = hl_main();
	//printf("**** EXIT with code %d ****\n", ret);
	while( true ) {}
}