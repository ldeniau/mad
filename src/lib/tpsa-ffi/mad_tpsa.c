#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#include "mad_tpsa.h"
#include "tpsa_utils.tc"
#include "tpsa_desc.tc"
//#include "mem_alloc.h"

// #define TRACE

#define T struct tpsa
#define D struct tpsa_desc

struct tpsa { // warning: must be kept identical to LuaJit definition
  D      *desc;
  ord_t   lo, hi, mo; // lowest/highest used ord, trunc ord
  bit_t   nz;
  num_t   coef[];
};

// --- DEBUGGING --------------------------------------------------------------

void
mad_tpsa_print_compact(const T *t)
{
  D *d = t->desc;
  printf("{ nz=%d lo=%d hi=%d mo=%d | ", t->nz, t->lo, t->hi, t->mo);
  ord_t hi = min_ord(t->hi, t->mo, t->desc->trunc);
  for (int i = d->hpoly_To_idx[t->lo]; i < d->hpoly_To_idx[hi+1]; ++i)
    if (t->coef[i])
      printf("[%d]=%.2f ", i, t->coef[i]);
  printf(" }\n");
}

// --- PUBLIC FUNCTIONS -------------------------------------------------------

// --- --- TOOLS --------------------------------------------------------------

T*
mad_tpsa_newd(D *d, const ord_t *trunc_ord_)
{
  assert(d);

  ord_t mo = d->mo;
  if (trunc_ord_) {
    ensure(*trunc_ord_ <= d->mo && *trunc_ord_ >= 1);
    mo = *trunc_ord_;
  }

  int needed_coef = d->hpoly_To_idx[mo+1];
  T *t = malloc(sizeof(T) + needed_coef * sizeof(num_t));
  assert(t);
#ifdef TRACE
  printf("tpsa new %p from %p with mo=%d\n", (void*)t, (void*)d, *trunc_ord_);
#endif
  t->desc = d;
  t->lo = t->mo = mo;
  t->hi = t->nz = t->coef[0] = 0;  // coef[0] used without checking in mul
  return t;
}

T*
mad_tpsa_new(const T *t)
{
  assert(t && t->desc);
  return mad_tpsa_newd(t->desc, &t->mo);
}

void
mad_tpsa_copy(const T *src, T *dst)
{
  assert(src && dst);
  assert(src->desc == dst->desc);
  D *d = src->desc;
  if (d->trunc < src->lo) {
    mad_tpsa_reset(dst);
    return;
  }
  dst->hi = min_ord(src->hi, dst->mo, d->trunc);
  dst->lo = src->lo;
  dst->nz = btrunc(src->nz, dst->hi);
  for (int i = d->hpoly_To_idx[dst->lo]; i < d->hpoly_To_idx[dst->hi+1]; ++i)
    dst->coef[i] = src->coef[i];
#ifdef TRACE
  printf("Copied from %p to %p\n", (void*)src, (void*)dst);
#endif
}

void
mad_tpsa_reset(T *t)
{
  assert(t);
  t->hi = t->nz = t->coef[0] = 0;
  t->lo = t->mo;
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
  idx_t i = desc_get_idx(d,n,m);
  ensure(d->ords[i] <= t->mo);
  return t->lo <= d->ords[i] && d->ords[i] <= t->hi ? t->coef[i] : 0;
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

// --- mono is sparse; represented as [(i o)]
num_t
mad_tpsa_getm_sp(const T *t, int n, const idx_t m[n])
{
  assert(t && m);
  D *d = t->desc;
  idx_t i = desc_get_idx_sp(d,n,m);
  ensure(d->ords[i] <= t->mo);
  return t->lo <= d->ords[i] && d->ords[i] <= t->hi ? t->coef[i] : 0;
}

void
mad_tpsa_setm_sp(T *t, int n, const idx_t m[n], num_t v)
{
  assert(t && m);
#ifdef TRACE
  printf("set_mono_sp: [ ");
  for (int i=0; i < n; ++i)
    printf("%d ", (int)m[i]);
  printf("]\n");
#endif
  idx_t i = desc_get_idx_sp(t->desc,n,m);
  mad_tpsa_seti(t,i,v);
}

num_t
mad_tpsa_geti(const T *t, int i)
{
  assert(t);
  D *d = t->desc;
  ensure(i >= 0 && i < d->nc);
  return t->lo <= d->ords[i] && d->ords[i] <= t->hi ? t->coef[i] : 0;
}

void
mad_tpsa_seti(T *t, int i, num_t v)
{
#ifdef TRACE
  printf("set_idx for %p i=%d v=%lf\n", (void*)t, i, v);
#endif
  assert(t);
  D *d = t->desc;
  ensure(i >= 0 && i < d->nc && d->ords[i] <= t->mo && d->ords[i] <= d->trunc);

  if (v == 0) {
    t->coef[i] = v;
    if (i == 0 && t->lo == 0) {
      t->nz = bclr(t->nz,0);
      t->lo = min_ord2(b_lowest(t->nz),t->mo);
    }
    return;
  }

  ord_t o = d->ords[i];
  t->nz = bset(t->nz,o);
  if (t->lo > t->hi) {    // new TPSA
    for (int c = d->hpoly_To_idx[o]; c < d->hpoly_To_idx[o+1]; ++c)
      t->coef[c] = 0;
    t->lo = t->hi = o;
  }
  else if (o > t->hi) {
    for (int c = d->hpoly_To_idx[t->hi+1]; c < d->hpoly_To_idx[o+1]; ++c)
      t->coef[c] = 0;
    t->hi = o;
  }
  else if (o < t->lo) {
    for (int c = d->hpoly_To_idx[o]; c < d->hpoly_To_idx[t->lo]; ++c)
      t->coef[c] = 0;
    t->lo = o;
  }
  t->coef[i] = v;
}

void
mad_tpsa_setConst(T *t, num_t v)
{
  assert(t);
  if (v) {
    t->coef[0] = v;
    t->nz = 1;
    t->lo = t->hi = 0;
  }
  else
    mad_tpsa_reset(t);
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
  ord_t hi = min_ord2(a->hi, a->desc->trunc);
  int *pi = a->desc->hpoly_To_idx;
  for (int o = a->lo; o <= hi; ++o)
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
  num_t norm = 0.0;
  ord_t hi = min_ord2(a->hi, a->desc->trunc);
  int *pi = a->desc->hpoly_To_idx;
  for (int o = a->lo; o <= hi; ++o)
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
  ensure(NULL && "Not maintained");
  D *d = a->desc;
  a->hi = min_ord2(a->mo, d->trunc);
  a->lo = 0;

  for (int i = 0; i < d->hpoly_To_idx[a->hi+1]; ++i)
    a->coef[i] = low + rand() / (RAND_MAX/(high-low));
  a->nz = (1 << (a->hi+1)) - 1;  // set all [0,hi]
}

#undef T
#undef D
#undef TRACE

// --- --- OPERATIONS ---------------------------------------------------------

#include "tpsa_io.tc"

#include "tpsa_ops.tc"

// #include "tpsa_fun.tc"

// #include "tpsa_compose.tc"

// #include "tpsa_minv.tc"

