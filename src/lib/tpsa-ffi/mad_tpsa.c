#include <string.h>
#include <stdlib.h>
#include <assert.h>
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
  for (int i = 0; i < t->desc->nc; ++i)
    t->coef[i] = 0;
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
  dst->mo = src->mo;
  dst->nz = src->nz;
  for (int i = 0; i < src->desc->nc; ++i)
    dst->coef[i] = src->coef[i];
#ifdef TRACE
  printf("Copied from %p to %p\n", (void*)src, (void*)dst);
#endif
}

T*
mad_tpsa_clone(const T *src)
{
  assert(src);
  T *res = mad_tpsa_newd(src->desc);
  mad_tpsa_copy(src, res);
  return res;
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
  assert(n <= t->desc->nv);
  idx_t i = desc_get_idx(t->desc,n,m);
  return t->coef[i];
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
  assert(i >= 0 && i < t->desc->nc);
  return t->coef[i];
}

void
mad_tpsa_seti(T *t, int i, num_t v)
{
#ifdef TRACE
  printf("mad_tpsa_seti for %p i=%d v=%lf\n", (void*)t, i, v);
#endif
  assert(t);
  assert(i >= 0 && i < t->desc->nc);
  ord_t *ords = t->desc->ords;
  t->coef[i] = v;
  if (ords[i] > t->mo) t->mo = ords[i];
  if (v != 0)          t->nz = bset(t->nz, ords[i]);
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
  for (int i = 0; i < a->desc->hpoly_To_idx[a->mo+1]; ++i)
    norm += fabs(a->coef[i]);
  return norm;
}

num_t
mad_tpsa_abs2(const T *a)
{
  assert(a);
  num_t norm = 0;
  for (int i = 0; i < a->desc->hpoly_To_idx[a->mo+1]; ++i)
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

// --- --- OPERATIONS ---------------------------------------------------------
#include "tpsa_ops.tc"

#include "tpsa_compose.tc"

#include <stdio.h>

void
mad_tpsa_print(const T *t)
{
  D *d = t->desc;
  printf("{ nz=%d; mo=%d; ", t->nz, t->mo);
  for (int i=0; i < d->hpoly_To_idx[t->mo + 1]; ++i)
    if (t->coef[i])
      printf("[%d]=%.2f ", i, t->coef[i]);
  printf(" }\n");
}

// --- BENCHMARK --------------------------------------------------------------

#ifdef TPSA_MAIN

// gcc -DTPSA_MAIN -std=c99 -Wall -W -pedantic -O3 -fopenmp -static-libgcc  mad_*.c -o tpsa

#include <time.h>

int main(int argc, char **argv)
{
  fprintf(stderr, "Usage: tpsa nv mo nl [num_threads]\n");
  if (argc < 3)
    exit(1);
  int nv = atoi(argv[1]), mo = atoi(argv[2]), nl = atoi(argv[3]);
  if (argc >= 5) COMPOSE_NUM_THREADS = atoi(argv[4]);

  ord_t var_ords[nv];
  for (int v = 0; v < nv; ++v)
    var_ords[v] = mo;

  D *d = mad_tpsa_desc_new(nv, var_ords, mo);
  T *t = mad_tpsa_newd(d);

  int nc = d->nc, start_val = 1.1, inc = 0.1;
  for (int c = 0; c < nc; ++c) {
    mad_tpsa_seti(t, c, start_val);
    start_val += inc;
  }

  T *ma[nv], *mb[nv], *mc[nv];
  for (int i = 0; i < nv; ++i) {
    ma[i] = mad_tpsa_clone(t);
    mb[i] = mad_tpsa_clone(t);
    mc[i] = mad_tpsa_new  (t);
  }

  double t0 = omp_get_wtime();
  for (int l = 0; l < nl; ++l)
    mad_tpsa_compose(nv, (const T**)ma, nv, (const T**)mb, nv, mc);
  double t1 = omp_get_wtime();

  printf("%d\t%d\t%d\t%d\t%d\t%.3f\n", nv, mo, nc, nl, COMPOSE_NUM_THREADS, t1-t0);

  return 0;
}

#endif

#undef T
#undef D
#undef TRACE
