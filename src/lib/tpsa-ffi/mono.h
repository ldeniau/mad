#ifndef MONO_H
#define MONO_H

typedef unsigned char mono_t;
typedef struct table  table_t;

void mono_clr(int n, mono_t m[n]);
void mono_cpy(const int n, const mono_t src[n], mono_t dst[n]);
int  mono_sum(int n, const mono_t m[n]);
int  mono_elem_leq(int n, const mono_t a[n], const mono_t b[n]);
int  mono_isvalid(int n, const mono_t m[n], const mono_t a[n], const int o);
int  mono_nxt_by_var(int n, mono_t m[n], const mono_t a[n], const int o);
void mono_print(int n, const mono_t m[n]);

int tbl_by_var(table_t* t, int nv, int no, int nc, const mono_t a[nv], mono_t mons[nc]);

#endif


