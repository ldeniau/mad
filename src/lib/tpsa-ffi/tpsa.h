#ifndef TPSA_H
#define TPSA_H

#include "defs.h"
#include "table.h"

struct desc {
  int      nv, mo, nc;
  table_t *Tv,
          *To;
  idx_t  **l;
};

struct tpsa { // warning: must be kept identical to LuaJit definition 
  desc_t *desc;
  int     mo;
  bit_t   nz;
  num_t   coef[];
};


tpsa_t* tpsa_new(desc_t *d);
void    tpsa_delete(tpsa_t* t);
int     tpsa_print(tpsa_t *t);
int     tpsa_setCoeff(tpsa_t *t, idx_t i, int o, num_t v);
int     tpsa_add(const tpsa_t *a, const tpsa_t *b, tpsa_t *c);
int     tpsa_sub(const tpsa_t *a, const tpsa_t *b, tpsa_t *c);
int     tpsa_mul(const tpsa_t *a, const tpsa_t *b, tpsa_t *c);

#endif
