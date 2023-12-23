#include "libc.h"

extern void kpanic( const char *msg );
extern void kprint( const char *msg );
extern void kprint_char( char c );

void libc_panic( const char *fun, int line ) {
	/*char buf[256];
	sprintf(buf, "*** LIBC PANIC %s:%d ***", fun, line);
	kpanic(buf);*/
	kpanic(fun);
}

#define PANIC() libc_panic(__func__,__LINE__)

static char *MALLOC_START_ADDR = (char*)0x00010000;

void *malloc(size_t size) {
	char *ptr = MALLOC_START_ADDR;
	MALLOC_START_ADDR += size;
	return ptr;
}

void free( void *ptr ) {
	// TODO
}

void memcpy(void *s1, const void *s2, size_t n) {
	unsigned char *_s1 = (unsigned char *)s1;
	unsigned char *_s2 = (unsigned char *)s2;
	while( n-- )
		*_s1++ = *_s2++;
}

void memset(void *s, int c, size_t n) {
	unsigned char *_s = (unsigned char *)s;
	unsigned char cc = (unsigned char)c;
	while( n-- )
		*_s++ = cc;
}

void memmove(void *s1, const void *s2, size_t n) {
	PANIC();
}

int memcmp(const void *s1, const void *s2, size_t n) {
	PANIC();
	return 0;
}

// string

int strcmp(const char *s1, const char *s2) {
	PANIC();
	return 0;
}

char *strchr(const char *s, int c) {
	PANIC();
	return NULL;
}

int strlen(const char *s) {
	PANIC();
	return 0;
}

void strcpy(char *dest, const char *src) {
	PANIC();
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
	PANIC();
	return 0;
}

// other

void exit( int code ) {
	PANIC();
}

void *dlopen( const char *path, void *mode ) {
	PANIC();
	return NULL;
}

void *dlsym( void *handler, const char *symbol ) {
	PANIC();
	return NULL;
}

int setjmp( jmp_buf env ) {
	PANIC();
	return 0;
}

void longjmp( jmp_buf env, int result ) {
	PANIC();
}

void *sys_alloc_align( int size, int align ) {
	PANIC();
	return NULL;
}

void sys_free_align( void *ptr, int size ) {
	PANIC();
}

