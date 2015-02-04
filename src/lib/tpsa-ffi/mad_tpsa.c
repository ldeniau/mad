#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include "mad_tpsa.h"
#include "tpsa_utils.tc"
#include "tpsa_desc.tc"
//#include "mem_alloc.h"

// #define TRACE

#define T struct tpsa
#define D struct tpsa_desc

struct tpsa { // warning: must be kept identical to LuaJit definition
  D      *desc;
  int     mo;
  bit_t   nz;
  num_t   coef[];
};

// --- DEBUGGING --------------------------------------------------------------

static inline void
print_l(const idx_t const* l)
{
  printf("l=%p\n", (void*)l);
  int s = l[0];
  printf("s=%d\n", s);
  for (int i=1; i < s*s; i++)
    printf("%d ", l[i]);
  printf("\n");
}

void
print_wf(const T *t)
{
  D *d = t->desc;
  printf("[ nz=%d; mo=%d; ", t->nz, t->mo);
  for (int o = t->mo; o >= 0; --o)
    for (int i = d->hpoly_To_idx[o]; i < d->hpoly_To_idx[o+1]; ++i)
      printf("%.2f ", t->coef[i]);
  printf(" ]\n");
}

// --- PUBLIC FUNCTIONS -------------------------------------------------------

// --- --- TOOLS --------------------------------------------------------------

T*
mad_tpsa_newd(D *d)
{
  assert(d);
  T *t = malloc(sizeof(T) + d->nc * sizeof(num_t));
  assert(t);
#ifdef TRACE
  printf("tpsa new %p from %p\n", (void*)t, (void*)d);
#endif
  t->desc = d;
  t->mo = 0;
  t->nz = 0;
  t->coef[0] = 0;  // used without initialisation in mul
  return t;
}

T*
mad_tpsa_new(const T *t)
{
  assert(t && t->desc);
  return mad_tpsa_newd(t->desc);
}

void
mad_tpsa_copy(const T *src, T *dst)
{
  assert(src && dst);
  assert(src->desc == dst->desc);
  D *d = src->desc;
  dst->mo = min_ord(src->mo, d->trunc);
  dst->nz = btrunc(src->nz, dst->mo);
  for (int i = 0; i < d->hpoly_To_idx[dst->mo+1]; ++i)
    dst->coef[i] = src->coef[i];
#ifdef TRACE
  printf("Copied from %p to %p\n", (void*)src, (void*)dst);
#endif
}

void
mad_tpsa_clean(T *t)
{
  assert(t && t->coef);
  for (int i = 0; i < t->desc->nc; ++i) t->coef[i] = 0;
  t->nz = t->mo = 0;
}

void
mad_tpsa_del(T* t)
{
#ifdef TRACE
  printf("tpsa del %p\n", (void*)t);
#endif
  free(t);
}

num_t
mad_tpsa_getm(const T *t, int n, const ord_t m[n])
{
  assert(t && m);
  D *d = t->desc;
  assert(n <= d->nv);
  idx_t i = desc_get_idx(d,n,m);
  return bget(t->nz,d->ords[i]) ? t->coef[i] : 0;
}

void
mad_tpsa_setm(T *t, int n, const ord_t m[n], num_t v)
{
  assert(t && m);
  assert(n <= t->desc->nv);
#ifdef TRACE
  printf("set coeff in %p with val %.2f for mon ", (void*)t, v);
  mono_print(n, m); printf("\n");
#endif
  idx_t i = desc_get_idx(t->desc,n,m);
  mad_tpsa_seti(t,i,v);
}

num_t
mad_tpsa_geti(const T *t, int i)
{
  assert(t);
  D *d = t->desc;
  assert(i >= 0 && i < d->nc);
  return bget(t->nz,d->ords[i]) ? t->coef[i] : 0;
}

void
mad_tpsa_seti(T *t, int i, num_t v)
{
#ifdef TRACE
  printf("mad_tpsa_seti for %p i=%d v=%lf\n", (void*)t, i, v);
#endif
  assert(t);
  D *d = t->desc;
  assert(i >= 0 && i < d->nc && d->ords[i] <= d->trunc);
  if (v == 0) {
    t->coef[i] = v;
    return;
  }

  ord_t o = d->ords[i];
  if (! bget(t->nz,o)) {
    t->nz = bset(t->nz, o);
    int *pi = d->hpoly_To_idx;
    for (int c = pi[o]; c < pi[o+1]; ++c)
      t->coef[i] = 0;
  }
  t->mo = o > t->mo ? o : t->mo;
  t->coef[i] = v;
}

int
mad_tpsa_get_idx(const T *t, int n, const ord_t m[n])
{
  assert(t && t->desc);
  assert(n <= t->desc->nv);
  return desc_get_idx(t->desc, n, m);
}

#include <math.h>

num_t
mad_tpsa_abs(const T *a)
{
  assert(a);
  num_t norm = 0.0;
  ord_t mo = min_ord(a->mo, a->desc->trunc);
  for (int i = 0; i < a->desc->hpoly_To_idx[mo+1]; ++i)
    norm += fabs(a->coef[i]);
  return norm;
}

num_t
mad_tpsa_abs2(const T *a)
{
  assert(a);
  num_t norm = 0;
  ord_t mo = min_ord(a->mo, a->desc->trunc);
  for (int i = 0; i < a->desc->hpoly_To_idx[mo+1]; ++i)
    norm += a->coef[i] * a->coef[i];
  return norm;
}

void
mad_tpsa_rand(T *a, num_t low, num_t high, int seed)
{
  assert(a);
  srand(seed);
  for (int i = 0; i < a->desc->nc; ++i)
    a->coef[i] = low + rand() / (RAND_MAX/(high-low));
  a->mo = a->desc->mo;
  a->nz = (1 << (a->mo+1)) - 1;
}

void
mad_tpsa_print(const T *t)
{
  D *d = t->desc;
  printf("{ nz=%d; mo=%d; ", t->nz, t->mo);
  ord_t mo = min_ord(t->mo, t->desc->trunc);
  for (int i=0; i < d->hpoly_To_idx[mo+1]; ++i)
    if (bget(t->nz,d->ords[i]) && t->coef[i])
      printf("[%d]=%.2f ", i, t->coef[i]);
  printf(" }\n");
}

#undef T
#undef D

// --- --- OPERATIONS ---------------------------------------------------------
#include "tpsa_ops.tc"

#include "tpsa_fun.tc"

#include "tpsa_compose.tc"

#include "tpsa_minv.tc"

#undef TRACE
