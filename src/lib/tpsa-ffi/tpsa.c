#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include "tpsa.h"
#include "tpsa_desc.h"
#include "tpsa_desc.tc"
//#include "mem_alloc.h"

//#define TRACE

typedef unsigned int  bit_t;
typedef double        num_t;

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

static int
hpoly_triang_mul(const num_t *ca, const num_t *cb, num_t *cc, const idx_t const* l, int oa, int ps[])
{
  int iao = ps[oa], ibo = ps[oa];  // offsets for shifting to 0
  int l_size = (ps[oa+1]-ps[oa]) * (ps[oa+1]-ps[oa] + 1) / 2, oc = oa + oa;

#ifdef TRACE
  printf("triang_mul oa=%d ob=%d | ic->[%d,%d) ", oa, oa, ps[oc], ps[oc+1]);
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


static int
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

static int
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

static int
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

int
tpsa_get_size(int nv, mono_t var_ords[nv], mono_t mvo)
{ return tpsa_desc_get_nc(nv,var_ords,mvo); }

void
tpsa_init(tpsa_t *t, int nv, mono_t var_ords[nv], mono_t mvo)
{
  assert(t && t->coef);
  t->desc = tpsa_desc_get(nv, var_ords, mvo);
#ifdef TRACE
  printf("init %p from %p\n", (void*)t, (void*)t->desc);
#endif
  t->mo = 0;
  t->nz = 0;
  for (int i = 0; i < t->desc->nc; ++i)
    t->coef[i] = 0;
}

tpsa_t*
tpsa_new(int nv, mono_t var_ords[nv], mono_t mvo)
{
  desc_t *d = tpsa_desc_get(nv, var_ords, mvo);
  tpsa_t *t = malloc(sizeof(tpsa_t) + d->nc * sizeof(num_t));
#ifdef TRACE
  printf("tpsa new %p\n", (void*)t);
#endif
  tpsa_init(t, nv, var_ords, mvo);
  return t;
}

void
tpsa_cpy(tpsa_t *src, tpsa_t *dst)
{
  assert(src && dst);
  assert(src->desc == dst->desc);
  memcpy(src, dst, sizeof *src);
#ifdef TRACE
  printf("Copied %ld bytes from %p to %p\n", sizeof *src, (void*)src, (void*)dst);
#endif
}

void
tpsa_same(tpsa_t *src, tpsa_t *dst)
{
  assert(src && dst);
  assert(src->desc == dst->desc);
  dst->mo = src->mo;
  dst->nz = src->nz;
}

void
tpsa_delete(tpsa_t* t)
{
#ifdef TRACE
  printf("tpsa del %p\n", (void*)t);
#endif
  free(t);
}

int // error code
tpsa_print(const tpsa_t *t)
{
  desc_t *d = t->desc;
  printf("[ nz=%d; mo=%d; ", t->nz, t->mo);
  for (int i=0; i < d->nc; ++i)
    printf("%f ", t->coef[i]);
  printf(" ]\n");
  return 0;
}

int // error code
tpsa_setCoeff(tpsa_t *t, idx_t i, int o, num_t v)
{
#ifdef TRACE
  printf("setCoeff %d\n", i);
#endif
  assert(t);
  assert(t->desc);
  assert(o <= t->desc->mo);
  assert(i < t->desc->nc);
  if (o > t->mo)
    t->mo = o;
  t->nz = bset(t->nz, o);
  t->coef[i] = v;
  return 0;
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


