#ifndef TPSA_H
#define TPSA_H

#include "tpsa_desc.h"

typedef struct tpsa tpsa_t;
typedef double      num_t;

tpsa_t* tpsa_new(desc_t *d);
int     tpsa_get_nc(desc_t *d);
tpsa_t* tpsa_init(tpsa_t *t,   desc_t *d);
void    tpsa_cpy(tpsa_t *src, tpsa_t *dst);
void    tpsa_clr(tpsa_t *t);
void    tpsa_del(tpsa_t* t);
void    tpsa_print(const tpsa_t *t);

void    tpsa_set_coeff(tpsa_t *t, int n, mono_t m[n], num_t v);
void    tpsa_set_const(tpsa_t *t, num_t v);
num_t   tpsa_get_coeff(tpsa_t *t, int n, mono_t m[n]);
//int     tpsa_add(const tpsa_t *a, const tpsa_t *b, tpsa_t *c);
//int     tpsa_sub(const tpsa_t *a, const tpsa_t *b, tpsa_t *c);
int     tpsa_mul(const tpsa_t *a, const tpsa_t *b, tpsa_t *c);

#endif
