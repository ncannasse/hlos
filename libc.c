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
	PANIC();
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
					case 'X':
						{
							int i = va_arg(args, int);
							int digits = 1;
							if( i < 0 ) {
								*out++ = '-';
								i = -i;
							}
							while( (i>>(4*digits)) > 0xF && digits < 8 ) digits++;
							while( digits > 0 ) {
								int n = (i >> (digits * 4)) & 15;
								if( n < 10 )
									*out++ = '0' + n;
								else
									*out++ = 'A' + n - 10;
								digits--;
							}
						}
						goto sprintf_loop;
					default:
						kprint(fmt);
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
	PANIC();
	return 0;
}

double strtod(const char *str, char **end) {
	PANIC();
	return 0;
}

long int strtol (const char* str, char** endptr, int base) {
	PANIC();
	return 0;
}

// math

float fmodf( float x, float y ) {
	PANIC();
	return 0;
}

double fmod( double x, double y ) {
	PANIC();
	return 0;
}

#ifndef NAN
    static const unsigned long __nan[2] = {0xffffffff, 0x7fffffff};
    #define NAN (*(const float *) __nan)
#endif

double hl_nan() {
	return NAN;
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
	PANIC();
	return NULL;
}

static void error_func() {
	PANIC();
}

static char *SYMBOLS = NULL;
static int SYMBOLS_SIZE = 0;

void init_kernel_symbols( char *symbols, int symb_size ) {
	const char *header = "SYM_TBL_BEGIN";
	if( memcmp(symbols,header,strlen(header)) != 0 )
		kpanic("Invalid symbol table");
	SYMBOLS = symbols;
	SYMBOLS_SIZE = symb_size;
}

extern int hl_bytes_find( const char *where, int pos, int len, const char *which, int wpos, int wlen );

void *dlsym( void *handler, const char *symbol ) {
	int len = strlen(symbol);
	int pos = hl_bytes_find(SYMBOLS, 0, SYMBOLS_SIZE, symbol, 0, len);
	if( pos < 0 )
		return NULL;
	int addr = *(int*)(SYMBOLS + pos + len);
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

DEFINE_PRIM(_BOOL, sys_utf8_path, _NO_ARG);
DEFINE_PRIM(_VOID, sys_print, _BYTES);
DEFINE_PRIM(_BOOL, sys_is64, _NO_ARG);
DEFINE_PRIM(_BYTES, date_to_string, _I32 _REF(_I32));
DEFINE_PRIM(_I32, date_new, _I32 _I32 _I32 _I32 _I32 _I32);
