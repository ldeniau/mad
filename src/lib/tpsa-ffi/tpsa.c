#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include "tpsa.h"
#include "tpsa_desc.tc"
//#include "mem_alloc.h"

//#define TRACE

#define TRACE

typedef unsigned int  bit_t;

struct tpsa { // warning: must be kept identical to LuaJit definition 
  desc_t *desc;
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

static inline idx_t
desc_get_idx(const tpsa_t *t, int n, const mono_t m[n])
{ return t->desc->tvi[tbl_index_H(t->desc,m)]; }

static inline int
hpoly_triang_mul(const num_t *ca, const num_t *cb, num_t *cc, const idx_t const* l, int oa, int ps[])
{
  int iao = ps[oa], ibo = ps[oa];  // offsets for shifting to 0
  int l_size = (ps[oa+1]-ps[oa]) * (ps[oa+1]-ps[oa] + 1) / 2, oc = oa + oa;

#ifdef TRACE
  printf("triang_mul oa=%d ob=%d\n", oa, oa, ps[oc], ps[oc+1]);
#endif

  for (idx_t ib = ps[oa]; ib < ps[oa+1]; ib++)
  for (idx_t ia = ib + 1; ia < ps[oa+1]; ia++) {
    int il = hpoly_idx_triang(ib-ibo, ia-iao);
    assert(0 <= il && il < l_size);

    int ic = l[il];
    if (ic >= 0) {
      assert(ps[oc] <= ic && ic < ps[oc+1]);
      cc[ic] = cc[ic] + ca[ia]*cb[ib] + ca[ib]*cb[ia];
    }
  }

  for (int ia=ps[oa]; ia < ps[oa+1]; ia++) {
    int il = hpoly_idx_triang(ia-iao, ia-iao);
    assert(0 <= il && il < l_size);

    int ic = l[il];
    if (ic >= 0) {
      assert(ps[oc] <= ic && ic < ps[oc+1]);
      cc[ic] = cc[ic] + ca[ia]*cb[ia];
    }
  }
  return (ps[oa+1]-ps[oa]) * (ps[oa+1]-ps[oa]);
}

static inline int
hpoly_sym_mul (const num_t *ca, const num_t *cb, num_t *cc, const idx_t* l, int oa, int ob, int ps[])
{
#ifdef TRACE
  printf("sym_mul oa=%d ob=%d \n", oa, ob);
#endif
  int iao = ps[oa], ibo = ps[ob];  // offsets for shifting to 0
  int ia_size = ps[oa+1]-ps[oa], ib_size = ps[ob+1]-ps[ob];
  int l_size  = ia_size*ib_size, oc = oa+ob;

  for (idx_t ib=ps[ob]; ib < ps[ob+1]; ib++)
  for (idx_t ia=ps[oa]; ia < ps[oa+1]; ia++) {
    int il = hpoly_idx_rect(ib-ibo, ia-iao, ia_size);
    assert(0 <= il && il < l_size);

    int ic = l[il];
    if (ic >= 0) {
      assert(ps[oc] <= ic && ic < ps[oc+1]);
      cc[ic] = cc[ic] + ca[ia]*cb[ib] + ca[ib]*cb[ia];
    }
  }
  return (ps[oa+1]-ps[oa]) * (ps[ob+1]-ps[ob]) * 2;
}

static inline int
hpoly_asym_mul (const num_t *ca, const num_t *cb, num_t *cc, const idx_t* l, int oa, int ob, int ps[])
{
#ifdef TRACE
  printf("asym_mul oa=%d ob=%d \n", oa, ob);
#endif

  int iao = ps[oa], ibo = ps[ob];  // offsets for shifting to 0
  int ia_size = ps[oa+1]-ps[oa], ib_size = ps[ob+1]-ps[ob];
  int l_size  = ia_size*ib_size, oc = oa+ob;

  for (idx_t ib=ps[ob]; ib < ps[ob+1]; ib++)
  for (idx_t ia=ps[oa]; ia < ps[oa+1]; ia++) {
    int il = hpoly_idx_rect(ib-ibo, ia-iao, ia_size);
    assert(0 <= il && il < l_size);

    int ic = l[il];
    if (ic >= 0) {
      assert(ps[oc] <= ic && ic < ps[oc+1]);
      cc[ic] = cc[ic] + ca[ia]*cb[ib];
    }
  }
  return (ps[oa+1]-ps[oa]) * (ps[ob+1]-ps[ob]);
}

static inline int
hpoly_mul (const tpsa_t *a, const tpsa_t *b, tpsa_t *c)
{
#ifdef TRACE
  printf("poly_mul\n");
#endif
  desc_t *dc = c->desc;
  const idx_t *l = NULL;
  int *ps = dc->ps, hod = dc->mo / 2, comps = 0;
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

tpsa_t*
tpsa_new(desc_t *d)
{
  assert(d);
  tpsa_t *t = malloc(sizeof(tpsa_t) + d->nc * sizeof(num_t));
#ifdef TRACE
  printf("tpsa new %p from %p\n", (void*)t, (void*)d);
#endif
  return tpsa_init_wd(t,d);
}

int
tpsa_get_size_fd(desc_t *d)
{ assert(d); return sizeof(tpsa_t) + d->nc * sizeof(num_t); }

int
tpsa_get_size_ft(tpsa_t *t)
{ return tpsa_get_size_fd(t->desc); }

tpsa_t*
tpsa_init_wd(tpsa_t *t, desc_t *d)
{
#ifdef TRACE
  printf("init %p from %p\n", (void*)t, (void*)d);
#endif
  assert(t && t->coef && d);
  t->desc = d;
  t->mo = 0;
  t->nz = 0;
  for (int i = 0; i < t->desc->nc; ++i)
    t->coef[i] = 0;
  return t;
}

tpsa_t*
tpsa_init_wt(tpsa_t *src, tpsa_t *dst)
{ return tpsa_init_wd(src, dst->desc); }

void
tpsa_cpy(tpsa_t *src, tpsa_t *dst)
{
  assert(src && dst);
  assert(src->desc == dst->desc);
  int size = tpsa_get_size_fd(src->desc);
  memcpy(dst, src, size);
#ifdef TRACE
  printf("Copied %d bytes from %p to %p\n", size, (void*)src, (void*)dst);
#endif
}

tpsa_t*
tpsa_same(tpsa_t* src)
{ return tpsa_new(src->desc); }

void
tpsa_clr(tpsa_t *t)
{
  assert(t && t->coef);
  for (int i = 0; i < t->desc->nc; ++i) t->coef[i] = 0;
  t->nz = t->mo = 0;
}

void
tpsa_del(tpsa_t* t)
{
#ifdef TRACE
  printf("tpsa del %p\n", (void*)t);
#endif
  free(t);
}

void
tpsa_print(const tpsa_t *t)
{
  desc_t *d = t->desc;
  printf("[ nz=%d; mo=%d; ", t->nz, t->mo);
  for (int i=0; i < d->nc; ++i)
    printf("%.2f ", t->coef[i]);
  printf(" ]\n");
}

void
tpsa_set_coeff(tpsa_t *t, int n, mono_t m[n], num_t v)
{
  assert(t && m);
  assert(n <= t->desc->nv);
#ifdef TRACE
  printf("set coeff in %p with val %.2f for mon ", (void*)t, v);
  mono_print(t->desc->nv, m); printf("\n");
#endif
  idx_t i = desc_get_idx(t,n,m);
  mono_t *o = t->desc->o;
  t->coef[i] = v;
  if (o[i] > t->mo) t->mo = o[i];
  if (v != 0)       t->nz = bset(t->nz, o[i]);
}

void
tpsa_set_const(tpsa_t *t, num_t v)
{
  assert(t);
  mono_t m[t->desc->nv];
  mono_clr(t->desc->nv, m);
  tpsa_set_coeff(t, t->desc->nv, m, v);
}

num_t
tpsa_get_coeff(tpsa_t *t, int n, mono_t m[n])
{
  assert(t && m);
  assert(n <= t->desc->nv);
  idx_t i = desc_get_idx(t,n,m);
  return t->coef[i];
}

int // error code
tpsa_add(const tpsa_t *a, const tpsa_t *b, tpsa_t *c)
{
  (void)a; (void)b; (void)c;
  return 0;
}

int // error code
tpsa_sub(const tpsa_t *a, const tpsa_t *b, tpsa_t *c)
{
  (void)a; (void)b; (void)c;
  return 0;
}

int // error code
tpsa_mul(const tpsa_t *a, const tpsa_t *b, tpsa_t *c)
{
#ifdef TRACE
  printf("tpsa_mul\n");
#endif
  assert(a && b && c);
  assert(a->desc == b->desc && a->desc == c->desc);

  const num_t *ca = a->coef, *cb = b->coef;
  num_t *cc = c->coef;
  desc_t *dc = c->desc;

  c->nz = (ca[0] ? a->nz : 0) | (cb[0] ? b->nz : 0);
  c->mo = imin(a->mo + b->mo, dc->mo);

  cc[0] = ca[0]*cb[0];

  for (int i=1; i < dc->ps[c->mo+1]; i++)
    cc[i] = ca[0]*cb[i] + cb[0]*ca[i];

  int comps = (dc->nc-1) * 2 + 1;

  if (c->mo >= 2)
    comps += hpoly_mul(a, b, c);

  return comps;
}


