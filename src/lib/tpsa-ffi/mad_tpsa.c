#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include "mad_tpsa.h"
#include "tpsa_desc.tc"
//#include "mem_alloc.h"

//#define TRACE

typedef unsigned int  bit_t;

#define T struct tpsa
#define D struct tpsa_desc

struct tpsa { // warning: must be kept identical to LuaJit definition
  D      *desc;
  int     mo;
  bit_t   nz;
  num_t   coef[];
};

// == debug
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

// == helpers

static inline bit_t
bset (bit_t b, int n)
{
  return b | (1 << n);
}

static inline int
bget (bit_t b, int n)
{
  return b & (1 << n);
}

// == local functions

static inline int
hpoly_triang_mul(const num_t *ca, const num_t *cb, num_t *cc, const idx_t const* l, int oa, int pi[])
{
  int iao = pi[oa], ibo = pi[oa];  // offsets for shifting to 0
  int l_size = (pi[oa+1]-pi[oa]) * (pi[oa+1]-pi[oa] + 1) / 2, oc = oa + oa;

#ifdef TRACE
  printf("triang_mul oa=%d ob=%d\n", oa, oa);
#endif

  for (idx_t ib = pi[oa]; ib < pi[oa+1]; ib++)
  for (idx_t ia = ib + 1; ia < pi[oa+1]; ia++) {
    int il = hpoly_idx_triang(ib-ibo, ia-iao);
    assert(0 <= il && il < l_size);

    int ic = l[il];
    if (ic >= 0) {
      assert(pi[oc] <= ic && ic < pi[oc+1]);
      cc[ic] = cc[ic] + ca[ia]*cb[ib] + ca[ib]*cb[ia];
    }
  }

  for (int ia=pi[oa]; ia < pi[oa+1]; ia++) {
    int il = hpoly_idx_triang(ia-iao, ia-iao);
    assert(0 <= il && il < l_size);

    int ic = l[il];
    if (ic >= 0) {
      assert(pi[oc] <= ic && ic < pi[oc+1]);
      cc[ic] = cc[ic] + ca[ia]*cb[ia];
    }
  }
  return (pi[oa+1]-pi[oa]) * (pi[oa+1]-pi[oa]);
}

static inline int
hpoly_sym_mul (const num_t *ca, const num_t *cb, num_t *cc, const idx_t* l, int oa, int ob, int pi[])
{
#ifdef TRACE
  printf("sym_mul oa=%d ob=%d \n", oa, ob);
#endif
  int iao = pi[oa], ibo = pi[ob];  // offsets for shifting to 0
  int ia_size = pi[oa+1]-pi[oa], ib_size = pi[ob+1]-pi[ob];
  int l_size  = ia_size*ib_size, oc = oa+ob;

  for (idx_t ib=pi[ob]; ib < pi[ob+1]; ib++)
  for (idx_t ia=pi[oa]; ia < pi[oa+1]; ia++) {
    int il = hpoly_idx_rect(ib-ibo, ia-iao, ia_size);
    assert(0 <= il && il < l_size);

    int ic = l[il];
    if (ic >= 0) {
      assert(pi[oc] <= ic && ic < pi[oc+1]);
      cc[ic] = cc[ic] + ca[ia]*cb[ib] + ca[ib]*cb[ia];
    }
  }
  return (pi[oa+1]-pi[oa]) * (pi[ob+1]-pi[ob]) * 2;
}

static inline int
hpoly_asym_mul (const num_t *ca, const num_t *cb, num_t *cc, const idx_t* l, int oa, int ob, int pi[])
{
#ifdef TRACE
  printf("asym_mul oa=%d ob=%d \n", oa, ob);
#endif

  int iao = pi[oa], ibo = pi[ob];  // offsets for shifting to 0
  int ia_size = pi[oa+1]-pi[oa], ib_size = pi[ob+1]-pi[ob];
  int l_size  = ia_size*ib_size, oc = oa+ob;

  for (idx_t ib=pi[ob]; ib < pi[ob+1]; ib++)
  for (idx_t ia=pi[oa]; ia < pi[oa+1]; ia++) {
    int il = hpoly_idx_rect(ib-ibo, ia-iao, ia_size);
    assert(0 <= il && il < l_size);

    int ic = l[il];
    if (ic >= 0) {
      assert(pi[oc] <= ic && ic < pi[oc+1]);
      cc[ic] = cc[ic] + ca[ia]*cb[ib];
    }
  }
  return (pi[oa+1]-pi[oa]) * (pi[ob+1]-pi[ob]);
}

static inline int
hpoly_mul (const T *a, const T *b, T *c)
{
#ifdef TRACE
  printf("poly_mul\n");
#endif
  D *dc = c->desc;
  const idx_t *l = NULL;
  int *ps = dc->hpoly_To_idx, hod = dc->mo / 2, comps = 0;
  const num_t *ca  = a->coef, *cb  = b->coef;
  bit_t   nza = a->nz  ,  nzb = b->nz;
  num_t *cc  = c->coef;

#ifdef _OPENMP
#pragma omp parallel for
  for (int i=2; i <= c->mo; i++) {
    int oc = !(i & 1) ? 1+i/2 : c->mo+1-i/2;
#else
  for (int oc=2; oc <= c->mo; oc++) {
#endif

    for (int j=1; j <= (oc-1)/2; ++j) {
      int oa = oc-j, ob = j;            // oa != ob
      l = dc->L[oa*hod + ob];
      assert(l);

      if (bget(nza,oa) && bget(nzb,ob) && bget(nza,ob) && bget(nzb,oa)) {
        comps += hpoly_sym_mul(ca,cb,cc, l, oa,ob,ps);
        c->nz = bset(c->nz,oc);
      }
      else if (bget(nza,oa) && bget(nzb,ob)) {
        comps += hpoly_asym_mul(ca,cb,cc, l, oa,ob,ps);
        c->nz = bset(c->nz,oc);
      }
      else if (bget(nza,ob) && bget(nzb,oa)) {
        comps += hpoly_asym_mul(cb,ca,cc, l, oa,ob,ps);
        c->nz = bset(c->nz,oc);
      }
    }

    if (! (oc&1)) {  // even oc, triang matrix
      int hoc = oc/2;
      l = dc->L[hoc*hod + hoc];
      assert(l);
      if (bget(nza,hoc) && bget(nzb,hoc) ) {
        comps += hpoly_triang_mul(ca,cb,cc, l, hoc,ps);
        c->nz = bset(c->nz,oc);
      }
    }
  }
  return comps;
}

// == public functions

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

void
mad_tpsa_add(const T *a, const T *b, T *c)
{
  (void)a; (void)b; (void)c;
}

void
mad_tpsa_sub(const T *a, const T *b, T *c)
{
  (void)a; (void)b; (void)c;
}

void
mad_tpsa_mul(const T *a, const T *b, T *c)
{
#ifdef TRACE
  printf("tpsa_mul\n");
#endif
  assert(a && b && c);
  assert(a->desc == b->desc && a->desc == c->desc);

  const num_t *ca = a->coef, *cb = b->coef;
  num_t *cc = c->coef;
  D *dc = c->desc;

  c->nz = (ca[0] ? a->nz : 0) | (cb[0] ? b->nz : 0);
  c->mo = imin(a->mo + b->mo, dc->mo);

  cc[0] = ca[0]*cb[0];

  for (int i=1; i < dc->hpoly_To_idx[c->mo+1]; i++)
    cc[i] = ca[0]*cb[i] + cb[0]*ca[i];

  int comps = (dc->nc-1) * 2 + 1;

  if (c->mo >= 2)
    comps += hpoly_mul(a, b, c);

//return comps;
}


void
mad_tpsa_print(const T *t)
{
  D *d = t->desc;
  printf("[ nz=%d; mo=%d; ", t->nz, t->mo);
  for (int i=0; i < d->nc; ++i)
    printf("%.2f ", t->coef[i]);
  printf(" ]\n");
}

#undef T
#undef D
#undef TRACE