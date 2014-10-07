#ifndef TPSA_H
#define TPSA_H

struct tpsa;
struct tpsa_desc;

typedef double        num_t;
typedef unsigned char mono_t;

#define T struct tpsa

T*    tpsa_new    (struct tpsa_desc *d);
void  tpsa_copy   (T *src, T *dst);
void  tpsa_clean  (T *t);
void  tpsa_del    (T* t);

num_t tpsa_getm (T *t, int n, mono_t m[n]);
void  tpsa_setm (T *t, int n, mono_t m[n], num_t v);

num_t tpsa_geti (T *t, int i);
void  tpsa_seti (T *t, int i, num_t v);

int   tpsa_get_idx (T *t, int n, mono_t m[n]);

void  tpsa_add (const T *a, const T *b, T *c);
void  tpsa_sub (const T *a, const T *b, T *c);
void  tpsa_mul (const T *a, const T *b, T *c);

void  tpsa_print (const T *t);

#undef T

#endif
