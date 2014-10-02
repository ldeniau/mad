#ifndef TPSA_H
#define TPSA_H

#include "tpsa_desc.h"

typedef struct tpsa tpsa_t;

tpsa_t* tpsa_new(desc_t *d);
int     tpsa_get_size(desc_t *d);
void    tpsa_init(tpsa_t *t, desc_t *d);

void    tpsa_cpy(tpsa_t *src, tpsa_t *dst);
void    tpsa_clr(tpsa_t *t);

void    tpsa_delete(tpsa_t* t);
void    tpsa_print(const tpsa_t *t);
//int     tpsa_add(const tpsa_t *a, const tpsa_t *b, tpsa_t *c);
//int     tpsa_sub(const tpsa_t *a, const tpsa_t *b, tpsa_t *c);
int     tpsa_mul(const tpsa_t *a, const tpsa_t *b, tpsa_t *c);

#endif
