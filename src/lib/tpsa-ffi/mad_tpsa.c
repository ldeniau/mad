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
  ord_t   mo, to; // max ord, trunc ord
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

void
mad_tpsa_print_compact(const T *t)
{
  D *d = t->desc;
  printf("{ nz=%d; mo=%d; ", t->nz, t->mo);
  ord_t mo = min_ord(t->mo, t->to, t->desc->trunc);
  for (int i=0; i < d->hpoly_To_idx[mo+1]; ++i)
    if (bget(t->nz,d->ords[i]) && t->coef[i])
      printf("[%d]=%.2f ", i, t->coef[i]);
  printf(" }\n");
}

// --- PUBLIC FUNCTIONS -------------------------------------------------------

// --- --- TOOLS --------------------------------------------------------------

T*
mad_tpsa_newd(D *d, const ord_t *trunc_ord_)
{
  assert(d);

  ord_t to = d->mo;
  if (trunc_ord_) {
    ensure(*trunc_ord_ <= d->mo);
    to = *trunc_ord_;
  }

  int needed_coef = d->hpoly_To_idx[to+1];
  T *t = malloc(sizeof(T) + needed_coef * sizeof(num_t));
  assert(t);
#ifdef TRACE
  printf("tpsa new %p from %p\n", (void*)t, (void*)d);
#endif
  t->desc = d;
  t->mo = 0;
  t->to = to;
  t->nz = 0;
  t->coef[0] = 0;  // init ord 0 by default
  return t;
}

T*
mad_tpsa_new(const T *t)
{
  assert(t && t->desc);
  return mad_tpsa_newd(t->desc, &t->to);
}

void
mad_tpsa_copy(const T *src, T *dst)
{
  assert(src && dst);
  assert(src->desc == dst->desc);
  D *d = src->desc;
  dst->mo = min_ord(src->mo, dst->to, d->trunc);
  dst->nz = btrunc(src->nz, dst->mo);
  for (int o = 0; o <= dst->mo; ++o)
    if (bget(dst->nz,o))
      for (int i = d->hpoly_To_idx[o]; i < d->hpoly_To_idx[o+1]; ++i)
        dst->coef[i] = src->coef[i];
#ifdef TRACE
  printf("Copied from %p to %p\n", (void*)src, (void*)dst);
#endif
}

void
mad_tpsa_clean(T *t)
{
  assert(t);
  // do a hard clean; TODO: check if setting nz to 0 suffices
  for (int i = 0; i < t->desc->hpoly_To_idx[t->to+1]; ++i) t->coef[i] = 0;
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
  ensure(d->ords[i] <= t->to);
  return bget(t->nz,d->ords[i]) ? t->coef[i] : 0;
}

void
mad_tpsa_setm(T *t, int n, const ord_t m[n], num_t v)
{
  assert(t && m);
  assert(n <= t->desc->nv);
#ifdef TRACE
  printf("set_mono: "); mono_print(n, m); printf("\n");
#endif
  idx_t i = desc_get_idx(t->desc,n,m);
  mad_tpsa_seti(t,i,v);
}

num_t
mad_tpsa_geti(const T *t, int i)
{
  assert(t);
  D *d = t->desc;
  ensure(i >= 0 && i < d->nc);
  return (bget(t->nz,d->ords[i]) && d->ords[i] <= t->to) ? t->coef[i] : 0;
}

void
mad_tpsa_seti(T *t, int i, num_t v)
{
#ifdef TRACE
  printf("set_idx for %p i=%d v=%lf\n", (void*)t, i, v);
#endif
  assert(t);
  D *d = t->desc;
  ensure(i >= 0 && i < d->nc && d->ords[i] <= t->to && d->ords[i] <= d->trunc);
  if (v == 0) {
    t->coef[i] = v;
    return;
  }

  ord_t o = d->ords[i];
  if (! bget(t->nz,o)) {  // uninitialized ord
    t->nz = bset(t->nz, o);
    int *pi = d->hpoly_To_idx;
    for (int c = pi[o]; c < pi[o+1]; ++c)
      t->coef[c] = 0;
  }
  t->mo = o > t->mo ? o : t->mo;
  t->coef[i] = v;
}

void
mad_tpsa_setConst(T *t, num_t v)
{
  assert(t);
  t->mo = 0;
  t->nz = 1;
  t->coef[0] = v;
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
  ord_t mo = min_ord(a->mo, a->to, a->desc->trunc);
  int *pi = a->desc->hpoly_To_idx;
  for (int o = 0; o <= mo; ++o)
    if (bget(a->nz,o)) {
      for (int i = pi[o]; i < pi[o+1]; ++i)
        norm += fabs(a->coef[i]);
    }
  return norm;
}

num_t
mad_tpsa_abs2(const T *a)
{
  assert(a);
  num_t norm = 0;
  ord_t mo = min_ord(a->mo, a->to, a->desc->trunc);
  int *pi = a->desc->hpoly_To_idx;
  for (int o = 0; o <= mo; ++o)
    if (bget(a->nz,o)) {
      for (int i = pi[o]; i < pi[o+1]; ++i)
        norm += a->coef[i] * a->coef[i];
    }
  return norm;
}

void
mad_tpsa_rand(T *a, num_t low, num_t high, int seed)
{
  assert(a);
  srand(seed);
  D *d = a->desc;
  a->mo = min_ord(a->to, d->mo, d->trunc);

  for (int i = 0; i < d->hpoly_To_idx[a->mo+1]; ++i)
    a->coef[i] = low + rand() / (RAND_MAX/(high-low));
  a->nz = (1 << (a->mo+1)) - 1;  // set all [0,mo]
}

#undef T
#undef D
#undef TRACE

// --- --- OPERATIONS ---------------------------------------------------------

#include "tpsa_io.tc"

#include "tpsa_ops.tc"

#include "tpsa_fun.tc"

#include "tpsa_compose.tc"

#include "tpsa_minv.tc"

