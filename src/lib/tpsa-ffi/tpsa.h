#ifndef TPSA_H
#define TPSA_H

#include "tpsa_desc.h"

typedef struct tpsa tpsa_t;

tpsa_t* tpsa_new(int nv, mono_t var_ords[nv], mono_t mo);
void    tpsa_delete(tpsa_t* t);
int     tpsa_print(const tpsa_t *t);
int     tpsa_setCoeff(tpsa_t *t, int i, int o, double v);
int     tpsa_add(const tpsa_t *a, const tpsa_t *b, tpsa_t *c);
int     tpsa_sub(const tpsa_t *a, const tpsa_t *b, tpsa_t *c);
int     tpsa_mul(const tpsa_t *a, const tpsa_t *b, tpsa_t *c);

#endif
