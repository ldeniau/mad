#ifndef MONO_H
#define MONO_H

#include "defs.h"

void mono_clr(int n, mono_t m[n]);
void mono_cpy(const int n, const mono_t src[n], mono_t dst[n]);
int  mono_equ(const int n, const mono_t a[n], const mono_t b[n]);
void mono_add(const int n, const mono_t a[n], const mono_t b[n], mono_t c[n]);
int  mono_sum(int n, const mono_t m[n]);
void mono_acc(int n, const mono_t a[n], mono_t r[n]);
int  mono_elem_leq(int n, const mono_t a[n], const mono_t b[n]);
int  mono_isvalid(int n, const mono_t m[n], const mono_t a[n], const int o);
int  mono_nxt_by_var(int n, mono_t m[n], const mono_t a[n], const int o); // todo: change src, dst order
void mono_nxt_by_unk(int n, const mono_t a[n], int i, int j, mono_t m[n]);
void mono_print(int n, const mono_t m[n]);

#endif


