#include <hl.h>

extern void kpanic( const char *msg );
extern void kprint( const char *msg );
extern void kprint_char( char c );

void libc_panic( const char *file, const char *fun, int line ) {
	char buf[256];
	sprintf(buf, "LIBC ERROR %s(%s:%d)", fun, file, line);
	kpanic(buf);
}

static char *MALLOC_START_ADDR = (char*)0x01000000;

void *malloc(size_t size) {
	if( size >= 4 ) {
		int r = ((int)MALLOC_START_ADDR)&3;
		if( r != 0 ) MALLOC_START_ADDR += 4 - r;
	}
	char *ptr = MALLOC_START_ADDR;
	MALLOC_START_ADDR += size;
	return ptr;
}

void free( void *ptr ) {
	// TODO
}

void *sys_alloc_align( int size, int align ) {
	int delta = ((int)MALLOC_START_ADDR) % align;
	if( delta ) MALLOC_START_ADDR += align - delta;
	return malloc(size);
}

void sys_free_align( void *ptr, int size ) {
	free(ptr);
}

void memcpy(void *dst, const void *src, size_t n) {
	unsigned char *_dst = (unsigned char *)dst;
	unsigned char *_src = (unsigned char *)src;
	while( n-- )
		*_dst++ = *_src++;
}

void memset(void *s, int c, size_t n) {
	unsigned char *_s = (unsigned char *)s;
	unsigned char cc = (unsigned char)c;
	while( n-- )
		*_s++ = cc;
}

void memmove(void *dst, const void *src, size_t n) {
	if( dst < src )
		memcpy(dst, src, n);
	else {
		unsigned char *_dst = (unsigned char *)dst;
		unsigned char *_src = (unsigned char *)src;
		while( n-- )
			_dst[n] = _src[n];
	}
}

int memcmp(const void *s1, const void *s2, size_t n) {
	unsigned char *_s1 = (unsigned char *)s1;
	unsigned char *_s2 = (unsigned char *)s2;
	while( n ) {
		int d = *_s1 - *_s2;
		if( d != 0 ) return d;
		_s1++;
		_s2++;
		n--;
	}
	return 0;
}

extern int hl_bytes_find( const char *where, int pos, int len, const char *which, int wpos, int wlen );

void *memfind(const void *s1, int len, const void *s2, int len2) {
	int pos = hl_bytes_find(s1, 0, len, s2, 0, len2);
	if( pos < 0 )
		return NULL;
	return (char*)s1 + pos;
}


// string

int strcmp(const char *s1, const char *s2) {
	while(true) {
		int d = *s1 - *s2;
		if( d != 0 ) return d;
		if( *s1 == 0 ) break;
		s1++;
		s2++;
	}
	return 0;
}

char *strchr(const char *s, int c) {
	while( *s ) {
		if( *s == c )
			return (char*)s;
		s++;
	}
	return NULL;
}

int strlen(const char *s) {
	int len = 0;
	while( *s++ ) len++;
	return len;
}

void strcpy(char *dest, const char *src) {
	while( *src )
		*dest++ = *src++;
}

int printf(const char *format, ...) {
	char buf[1024];
	int ret;
	va_list args;
	va_start(args, format);
	ret = vsprintf(buf, format, args);
	va_end(args);
	kprint(buf);
	return ret;
}

int sprintf(char *s, const char *format, ...) {
	int ret;
	va_list args;
	va_start(args, format);
	ret = vsprintf(s, format, args);
	va_end(args);
	return ret;
}

int vsprintf(char *out, const char *fmt, va_list args ) {
	char *start = out;
	char c;
	while(true) {
sprintf_loop:
		c = *fmt++;
		switch( c ) {
		case 0:
			*out = 0;
			return (int)(out - start);
		case '%':
			{
				const char *start = fmt;
				while( true ) {
					c = *fmt++;
					switch( c ) {
					case 's':
						char *s = va_arg(args,char *);
						while( *s )
							*out++ = *s++;
						goto sprintf_loop;
					case 'd':
						{
							int i = va_arg(args, int);
							int digits = 1;
							if( i < 0 ) {
								*out++ = '-';
								i = -i;
							}
							while( (i/10) >= digits && digits < 1000000000 ) digits *= 10;
							while( digits > 0 ) {
								int n = (i / digits) % 10;
								*out++ = '0' + n;
								digits /= 10;
							}
						}
						goto sprintf_loop;
					case 'f':
					case 'g':
						{
							const double EPSILON = 1e-9;
							double d = va_arg(args, double);
							int digits = 0;
							if( d < 0 ) {
								*out++ = '-';
								d = -d;
							}
							while( d >= 1 ) {
								d *= 0.1;
								digits++;
							}
							if( digits == 0 )
								*out++ = '0';
							while( digits > 0 && d > EPSILON ) {
								d *= 10;
								int n = (int)(d + EPSILON);
								*out++ = '0' + n;
								d -= n;
								digits--;
							}
							while( digits ) {
								*out++ = '0';
								digits--;
							}
							if( d > EPSILON ) {
								*out++ = '.';
								// this is approximate but gives good results
								while( d > EPSILON && digits < 15 ) {
									d *= 10;
									int n = (int)(d + EPSILON);
									*out++ = '0' + n;
									d -= n;
									digits++;
								}
							}
						}
						goto sprintf_loop;
					case 'X':
						{
							unsigned int i = va_arg(args, unsigned int);
							int digits = 0;
							while( (i>>(4*digits)) != 0 && digits < 8 ) digits++;
							if( digits == 0 ) digits++;
							while( digits > 0 ) {
								digits--;
								int n = (i >> (digits * 4)) & 15;
								if( n < 10 )
									*out++ = '0' + n;
								else
									*out++ = 'A' + n - 10;
							}
						}
						goto sprintf_loop;
					case '0':
					case '1':
					case '2':
					case '3':
					case '4':
					case '5':
					case '6':
					case '7':
					case '8':
					case '9':
					case '.':
						continue;
					default:
						kprint(start);
						PANIC();
						break;
					}
				}
			}
			break;
		default:
			*out++ = c;
			break;
		}
	}
	return 0;
}

int atoi(const char *str) {
	return strtol(str, NULL, 10);
}

double strtod( const char *str, char **endptr ) {
	int m = 1;
	double d = 0.;
	double exp = 0.;
	if( *str == '-' ) { m = -1; str++; }
	while( true ) {
		int c = *str++;
		if( c == '.' ) {
			if( exp != 0 ) break;
			exp = 1;
			continue;
		}
		if( c < '0' || c > '9' ) {
			str--;
			break;
		}
		exp *= 10;
		d = d*10 + c - '0';
	}
	if( exp == 0 ) exp = 1;
	if( endptr ) *endptr = (char*)str;
	d = (d / exp) * m;
	return d;
}

long int strtol( const char* str, char** endptr, int base ) {
	if( base != 10 ) PANIC();
	int i = 0;
	int m = 1;
	if( *str == '-' ) { m = -1; str++; }
	while(true) {
		int c = *str++;
		if( c < '0' || c > '9' ) {
			str--;
			break;
		}
		i = i*10 + c - '0';
	}
	if( endptr ) *endptr = (char*)str;
	return i * m;
}

char *strdup( const char *s ) {
	int len = strlen(s);
	char *m = (char*)malloc(len + 1);
	strcpy(m, s);
	m[len] = 0;
	return m;
}

// math

double trunc( double orig ) {
	union {
		double d;
		struct {
			unsigned int low;
			unsigned int high;
		};
	} v;
	v.d = orig;
	unsigned int exp = v.high & (0x7FF << 20);
	if( exp >= (0x3FF << 20) ) {
		if( exp < ((0x3FF + 52) << 20) ) {
			if( exp <= ((0x3FF + 20) << 20) ) {
				unsigned shift = (exp >> 20) - 0x3FF;
				v.high &= ~(0xFFFFF >> shift);
				v.low = 0;
			} else {
				unsigned shift = (exp >> 20) - 0x3FF - 20;
				v.low &= ~(((unsigned)-1) >> shift);
			}
		}
	} else {
		v.high &= 0x800 << 20;
		v.low  = 0;
	}
	return v.d;
}

float fmodf( float x, float y ) {
	return x - trunc(x / y) * y;
}

double fmod( double x, double y ) {
	return x - trunc(x / y) * y;
}

double hl_nan() {
    static const union {
		unsigned long __nan[2];
		float fnan;
	} NAN = {{0xffffffff, 0x7fffffff}};
	return NAN.fnan;
}

// time

int gettimeofday( struct timeval *v, void *timezone ) {
	v->tv_sec = 0;
	v->tv_usec = 0;
	return 0;
}

// other

void exit( int code ) {
	printf("**** EXIT with code %d ****\n", code);
	while( true ) {}
}

void *dlopen( const char *path, void *mode ) {
	return (void*)path;
}

const char *load_kernel_file( const char *path, int *size );

static const char *SYMBOLS = NULL;
static int SYMBOLS_SIZE = 0;

struct _unreg_function {
	const char *lib;
	const char *name;
	unsigned short entry;
	void *addr;
	unsigned short call_asm;
	unsigned short ret_asm;
	struct _unreg_function *next;
} __attribute__((packed));

typedef struct _unreg_function unreg_function;

static unreg_function *unregistered = NULL;

static void init_kernel_symbols() {
	SYMBOLS = load_kernel_file("kernel.sym", &SYMBOLS_SIZE);
	if( SYMBOLS == NULL ) kpanic("Symbols file not found");
}

static void runtime_failure( unsigned char *entry /* return eip of callee */ ) {
	unreg_function *f = NULL;
	f = (unreg_function*)(entry - (int)&f->entry);
	char buf[256];
	sprintf(buf, "Primitive %s@%s is missing", f->lib, f->name);
	kpanic(buf);
}

static void *last_unregistered( char **sign ) {
	*sign = NULL;
	return &unregistered->entry;
}

void *dlsym( void *handler, const char *symbol ) {
	if( SYMBOLS == NULL )
		init_kernel_symbols();
	int len = strlen(symbol);
	void *loc = memfind(SYMBOLS, SYMBOLS_SIZE, symbol, len + 1);
	if( loc == NULL ) {
		if( memcmp(symbol,"hlp_",4) != 0 )
			return NULL;
		unreg_function *f = malloc(sizeof(unreg_function));
		f->lib = handler == NULL ? "std" : strdup(handler);
		f->name = strdup(symbol + 4);
		f->entry = 0xB850; // PUSH EAX, MOV EAX, ...
		f->addr = runtime_failure;
		f->call_asm = 0xD0FF; // CALL EAX
		f->ret_asm = 0xC358; // POP EAX + RET
		f->next = unregistered;
		unregistered = f;
		return last_unregistered;
	}
	int addr = *(int*)((char*)loc + (len + 1));
	return (void*)addr;
}

int setjmp( jmp_buf env ) {
	return 0;
}

void longjmp( jmp_buf env, int result ) {
	PANIC();
}

bool hl_sys_utf8_path() {
	return true;
}

void hl_sys_print( vbyte *msg ) {
	uprintf(USTR("%s"),(uchar*)msg);
}

bool hl_sys_is64() {
	return false;
}

vbyte *hl_date_to_string( int date, int *len ) {
	PANIC();
	return NULL;
}

int hl_date_new( int y, int mo, int d, int h, int m, int s ) {
	PANIC();
	return 0;
}

static bool hl_define_function( const char *lib, const char *name, vdynamic *d ) {
	vclosure *c = (vclosure*)d;
	if( c->hasValue ) kpanic("Cannot define closure from function");
	unreg_function *f = unregistered;
	while( f ) {
		if( strcmp(lib, f->lib) == 0 && strcmp(name,f->name) == 0 ) {
			f->entry = 0xB890; // NOP + MOV EAX,...
			f->addr = c->fun;
			f->call_asm = 0xE0FF; // JMP EAX
			return true;
		}
		f = f->next;
	}
	return false;
}

DEFINE_PRIM(_BOOL, sys_utf8_path, _NO_ARG);
DEFINE_PRIM(_VOID, sys_print, _BYTES);
DEFINE_PRIM(_BOOL, sys_is64, _NO_ARG);
DEFINE_PRIM(_BYTES, date_to_string, _I32 _REF(_I32));
DEFINE_PRIM(_I32, date_new, _I32 _I32 _I32 _I32 _I32 _I32);

extern void int32( unsigned char intnum, void *regs );
_DEFINE_PRIM_WITH_NAME(_VOID, int32, _I32 _STRUCT, int32);
_DEFINE_PRIM_WITH_NAME(_BYTES, load_kernel_file, _BYTES _REF(_I32), load_kernel_file);
DEFINE_PRIM(_BOOL, define_function, _BYTES _BYTES _DYN);
