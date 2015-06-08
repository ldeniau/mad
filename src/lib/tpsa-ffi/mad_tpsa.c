#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>

#ifdef _OPENMP
#include <omp.h>
#endif

#include "mad_tpsa.h"
#include "mono.h"
#include "tpsa_utils.tc"
#include "tpsa_desc.tc"
// #include "mem_alloc.h"


// #define TRACE

#define T     struct tpsa
#define D     struct tpsa_desc
#define num_t double

const ord_t mad_tpsa_default   = -1;
const ord_t mad_tpsa_same      = -2;

struct tpsa { // warning: must be kept identical to LuaJit definition
  D      *desc;
  ord_t   lo, hi, mo; // lowest/highest used ord, trunc ord
  bit_t   nz;
  int     tmp;
  num_t   coef[];
};

// --- DEBUGGING --------------------------------------------------------------

void
mad_tpsa_debug(const T *t)
{
  D *d = t->desc;
  printf("{ nz=%d lo=%d hi=%d mo=%d | [0]=%g ", t->nz, t->lo, t->hi, t->mo, t->coef[0]);
  ord_t hi = min_ord(t->hi, t->mo, t->desc->trunc);
  int i = d->hpoly_To_idx[imax(1,t->lo)]; // ord 0 already printed
  for (; i < d->hpoly_To_idx[hi+1]; ++i)
    if (t->coef[i])
      printf("[%d]=%g ", i, t->coef[i]);
  printf(" }\n");
}

// --- PUBLIC FUNCTIONS -------------------------------------------------------

// --- --- INTROSPECTION ------------------------------------------------------
D*
mad_tpsa_desc(const T *t)
{
  assert(t);
  return t->desc;
}

ord_t
mad_tpsa_gtrunc(D *d, ord_t to)
{
  assert(d);
  ord_t orig = d->trunc;
  if (to == mad_tpsa_same)
    return orig;

  if (to == mad_tpsa_default)
    to = d->mo;
  else
    ensure(to <= d->mo);
  d->trunc = to;
  return orig;
}

ord_t
mad_tpsa_ord(const T *t)
{
  assert(t);
  return t->mo;
}

ord_t
(mad_tpsa_ordv)(const T *t1, const T *t2, ...)
{
  assert(t1 && t2);
  ord_t mo = t1->mo > t2->mo ? t1->mo : t2->mo;
  va_list args;
  va_start(args,t2);
  while ((t2 = va_arg(args,T*)))
    if (t2->mo > mo)
      mo = t2->mo;
  va_end(args);
  return mo;
}

int
mad_tpsa_maxsize(const D *d)
{
  assert(d);
  return d->nc;
}

ord_t
mad_tpsa_maxord(const D *d)
{
  assert(d);
  return d->mo;
}

// --- --- CTORS --------------------------------------------------------------

T*
mad_tpsa_newd(D *d, ord_t mo)
{
  assert(d);

  if (mo == mad_tpsa_default)
    mo = d->mo;
  else
    ensure(mo <= d->mo);

  T *t;
  if (d->stack_top > 0)
    t = d->stack[d->stack_top--];
  else {
    t = malloc(sizeof(T) + d->nc * sizeof(num_t));
    assert(t);
    t->desc = d;
  }
  t->lo = t->mo = mo;
  t->hi = t->nz = t->coef[0] = 0;  // coef[0] used without checking NZ[0]
  t->tmp = 0;
  return t;
}

T*
mad_tpsa_new(const T *t, ord_t mo)
{
  assert(t);
  if (mo == mad_tpsa_same)
    mo = t->mo;
  return mad_tpsa_newd(t->desc,mo);
}

T*
mad_tpsa_copy(const T *src, T *dst)
{
  assert(src && dst);
  ensure(src->desc == dst->desc);
  D *d = src->desc;
  if (d->trunc < src->lo) {
    mad_tpsa_clear(dst);
    return dst;
  }
  dst->hi = min_ord(src->hi, dst->mo, d->trunc);
  dst->lo = src->lo;
  dst->nz = btrunc(src->nz, dst->hi);
  // dst->tmp = src->tmp;  // managed from outside

  for (int i = d->hpoly_To_idx[dst->lo]; i < d->hpoly_To_idx[dst->hi+1]; ++i)
    dst->coef[i] = src->coef[i];
#ifdef TRACE
  printf("Copied from %p to %p\n", (void*)src, (void*)dst);
#endif
  return dst;
}

void
mad_tpsa_clear(T *t)
{
  assert(t);
  t->hi = t->nz = t->coef[0] = 0;
  t->lo = t->mo;
  // t->tmp = 0;  // managed from outside
}

void
mad_tpsa_del(T *t)
{
#ifdef TRACE
  printf("tpsa del %p\n", (void*)t);
#endif
  D *d = t->desc;
  if (d->stack_top < DESC_STACK_SIZE)
    d->stack[++d->stack_top] = t;
  else
    free(t);
}

void
(mad_tpsa_delv)(T *t1, T *t2, ...)
{
  assert(t1 && t2);
  mad_tpsa_del(t1);
  mad_tpsa_del(t2);
  va_list args;
  va_start(args,t2);
  while((t2 = va_arg(args,T*)))
    mad_tpsa_del(t2);
  va_end(args);
}

// --- --- INDEXING / MONOMIALS -----------------------------------------------

const ord_t*
mad_tpsa_mono(const T *t, int i, int *n, ord_t *total_ord_)
{
  assert(t && n);
  D *d = t->desc;
  ensure(0 <= i && i < d->nc);
  *n = d->nv;
  if (total_ord_)
    *total_ord_ = d->ords[i];
  return d->To[i];
}

int
mad_tpsa_midx(const T *t, int n, const ord_t m[n])
{
  assert(t && t->desc);
  assert(n <= t->desc->nv);
  return desc_get_idx(t->desc, n, m);
}

int
mad_tpsa_midx_sp(const T *t, int n, const int m[n])
{
  assert(t && t->desc);
  return desc_get_idx_sp(t->desc, n, m);
}


// --- --- ACCESSORS ----------------------------------------------------------

num_t
mad_tpsa_get0(const T *t)
{
  assert(t);
  return t->coef[0];
}

num_t
mad_tpsa_geti(const T *t, int i)
{
  assert(t);
  D *d = t->desc;
  ensure(i >= 0 && i < d->nc);
  return t->lo <= d->ords[i] && d->ords[i] <= t->hi ? t->coef[i] : 0;
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

num_t
mad_tpsa_getm_sp(const T *t, int n, const idx_t m[n])
{
  // --- mono is sparse; represented as [(i o)]
  assert(t && m);
  D *d = t->desc;
  idx_t i = desc_get_idx_sp(d,n,m);
  ensure(d->ords[i] <= t->mo);
  return t->lo <= d->ords[i] && d->ords[i] <= t->hi ? t->coef[i] : 0;
}

void
mad_tpsa_const(T *t, num_t v)
{
  assert(t);
  if (v) {
    t->coef[0] = v;
    t->nz = 1;
    t->lo = t->hi = 0;
  }
  else
    mad_tpsa_clear(t);
}

void
mad_tpsa_set0(T *t, num_t a, num_t b)
{
  assert(t);
  t->coef[0] = a*t->coef[0] + b;
  if (t->coef[0]) {
    t->nz = bset(t->nz,0);
    for (int c = t->desc->hpoly_To_idx[1]; c < t->desc->hpoly_To_idx[t->lo]; ++c)
      t->coef[c] = 0;
    t->lo = 0;
  }
  else {
    t->nz = bclr(t->nz,0);
    t->lo = min_ord2(b_lowest(t->nz),t->mo);
  }
}

void
mad_tpsa_seti(T *t, int i, num_t a, num_t b)
{
#ifdef TRACE
  printf("tpsa_seti for %p i=%d a=%lf b=%lf\n", (void*)t, i, a,b);
#endif
  assert(t);
  D *d = t->desc;
  ensure(i >= 0 && i < d->nc && d->ords[i] <= t->mo && d->ords[i] <= d->trunc);

  if (i == 0) { mad_tpsa_set0(t,a,b); return; }

  num_t v = a*mad_tpsa_geti(t,i) + b;
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
  if (t->lo > t->hi) {    // new TPSA, init ord o
    for (int c = d->hpoly_To_idx[o]; c < d->hpoly_To_idx[o+1]; ++c)
      t->coef[c] = 0;
    t->lo = t->hi = o;
  }
  else if (o > t->hi) {   // extend right
    for (int c = d->hpoly_To_idx[t->hi+1]; c < d->hpoly_To_idx[o+1]; ++c)
      t->coef[c] = 0;
    t->hi = o;
  }
  else if (o < t->lo) {   // extend left
    for (int c = d->hpoly_To_idx[o]; c < d->hpoly_To_idx[t->lo]; ++c)
      t->coef[c] = 0;
    t->lo = o;
  }
  t->coef[i] = v;
}

void
mad_tpsa_setm(T *t, int n, const ord_t m[n], num_t a, num_t b)
{
  assert(t && m);
  assert(n <= t->desc->nv);
#ifdef TRACE
  printf("set_mono: "); mono_print(n, m); printf("\n");
#endif
  idx_t i = desc_get_idx(t->desc,n,m);
  mad_tpsa_seti(t,i,a,b);
}

void
mad_tpsa_setm_sp(T *t, int n, const idx_t m[n], num_t a, num_t b)
{
  assert(t && m);
#ifdef TRACE
  printf("set_mono_sp: [ ");
  for (int i=0; i < n; i += 2)
    printf("%d %d  ", m[i], m[i+1]);
  printf("]\n");
#endif
  idx_t i = desc_get_idx_sp(t->desc,n,m);
  mad_tpsa_seti(t,i,a,b);
}

#undef T
#undef D
#undef TRACE

// --- --- OPERATIONS ---------------------------------------------------------
#include "tpsa_ops.tc"

#include "tpsa_io.tc"

#include "tpsa_fun.tc"

// #include "tpsa_compose.tc"

// #include "tpsa_minv.tc"

