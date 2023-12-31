#ifndef LIBC_H
#define LIBC_H

// types

#include <stddef.h>
#include <stdarg.h>
#include <stdbool.h>
typedef int intptr_t;
typedef unsigned int uintptr_t;
typedef unsigned short char16_t;

// mem

void *malloc(size_t size);
void free(void *ptr);

void memcpy(void *s1, const void *s2, size_t n);
void memset(void *s, int c, size_t n);
void memmove(void *s1, const void *s2, size_t n);
int memcmp(const void *s1, const void *s2, size_t n);
void *memfind(const void *s1, int len, const void *s2, int len2);

// string

int strcmp(const char *s1, const char *s2);
char *strchr(const char *s, int c);
int strlen(const char *s);
void strcpy(char *dest, const char *src);
int printf(const char *format, ...);
int sprintf(char *s, const char *format, ...);
int vsprintf(char *s, const char *format, va_list arg );
int atoi(const char *str);
double strtod(const char *str, char **end);
long int strtol(const char* str, char** endptr, int base);

// file I/O

struct _FILE;
typedef struct _FILE FILE;
#define fwrite(a,b,c,d)
#define fopen(a,b) NULL
#define fclose(_)
#define fflush(_)

// math

float fmodf( float x, float y );
double fmod( double x, double y );

// time

#define getpid() 0
struct timeval {
	long tv_sec;
	long tv_usec;
};
int gettimeofday( struct timeval *v, void *timezone ); // for random init

// other

#define RTLD_LAZY ((void*)1)
#define RTLD_DEFAULT NULL
void *dlopen( const char *path, void *mode );
void *dlsym( void *handler, const char *symbol );

struct jmp_buf_tag {
	void *edx;
	void *ebx;
	void *esp;
	void *ebp;
	void *esi;
	void *edi;
	void *mxcsr;
	void *fcw;
	double xmm[8];
	void *eip;
};

typedef struct jmp_buf_tag jmp_buf[1];

int setjmp( jmp_buf __env );
[[noreturn]] void longjmp( jmp_buf env, int result );
void exit( int i );

// hl wrappers
void *sys_alloc_align( int size, int align );
void sys_free_align( void *ptr, int size );
double hl_nan();

void libc_panic( const char *file, const char *fun, int line );
#define PANIC() libc_panic(__FILE__,__func__,__LINE__)

#endif
