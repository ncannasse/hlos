#include "libc.h"

extern void kpanic( const char *msg );

void libc_panic( const char *fun, int line ) {
	/*char buf[256];
	sprintf(buf, "*** LIBC PANIC %s:%d ***", fun, line);
	kpanic(buf);*/
	kpanic(fun);
}

#define PANIC() libc_panic(__func__,__LINE__)

void *malloc(size_t size) {
	PANIC();
	return NULL;
}

void free( void *ptr ) {
	PANIC();
}

void memcpy(void *s1, const void *s2, size_t n) {
	PANIC();
}

void memset(void *s, int c, size_t n) {
	PANIC();
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
	PANIC();
	return 0;
}

int sprintf(char *s, const char *format, ...) {
	PANIC();
	return 0;
}

int vsprintf(char *s, const char *format, va_list arg ) {
	PANIC();
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

