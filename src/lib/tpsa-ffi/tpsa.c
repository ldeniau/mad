#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>

//#define TRACE


typedef unsigned int  bit_t;
typedef unsigned char mono_t;
typedef double        coef_t;
typedef int           idx_t;
typedef struct desc   desc_t;
typedef struct tpsa   tpsa_t;

struct desc {
  int     nc, mo;
  idx_t **l;
  idx_t   psto[];
};

struct tpsa { // warning: must be kept identical to LuaJit definition 
  desc_t *desc;
  int     mo;
  bit_t   nz;
  int     id;
  coef_t  coef[];
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

static inline bit_t
bclr (bit_t b, int n)
{
  return b & ~(1 << n);
}

static inline int
bget (bit_t b, int n)
{
  return b & (1 << n);
}

static inline int
imin (int a, int b)
{
  return a<b ? a : b;
}

static inline idx_t
hpoly_idx_triang(idx_t ia, idx_t ib)
{
  return (ia*(ia+1))/2 + ib;
}

static inline idx_t
hpoly_idx_rect(idx_t ia, idx_t ib, int ib_size)
{
  return ia*ib_size + ib;
}

// == local functions

static int
hpoly_triang_mul(const coef_t *ca, const coef_t *cb, coef_t *cc, const idx_t const* l, int oa, int ps[])
{
#ifdef TRACE
  printf("triang_mul oa=%d ob=%d \n", oa, oa);
#endif
  int iao = ps[oa], ibo = ps[oa];  // offsets for shifting to 0
  for (idx_t ia=ps[oa]; ia < ps[oa+1]; ia++)
  for (idx_t ib=ps[oa]; ib <   ia    ; ib++) {
      int ic = l[ hpoly_idx_triang(ia-iao, ib-ibo) ];
      if (ic >= 0)
        cc[ic] = cc[ic] + ca[ia]*cb[ib] + ca[ib]*cb[ia];
  }

  for (int ia=ps[oa]; ia < ps[oa+1]; ia++) {
    int ic = l[ hpoly_idx_triang(ia-iao, ia-iao)];
    if (ic >= 0)
      cc[ic] = cc[ic] + ca[ia]*cb[ia];
  }
  return (ps[oa+1]-ps[oa]) * (ps[oa+1]-ps[oa]);
}


static int
hpoly_sym_mul (const coef_t *ca, const coef_t *cb, coef_t *cc, const idx_t const* l, int oa, int ob, int ps[])
{
#ifdef TRACE
  printf("sym_mul oa=%d ob=%d \n", oa, ob);
#endif
  int iao = ps[oa], ibo = ps[ob];  // offsets for shifting to 0
  int ib_size = ps[ob+1] - ps[ob];
  for (idx_t ia=ps[oa]; ia < ps[oa+1]; ia++)
  for (idx_t ib=ps[ob]; ib < ps[ob+1]; ib++) {
    int ic = l[ hpoly_idx_rect(ia-iao, ib-ibo, ib_size) ];
    if (ic >= 0)
      cc[ic] = cc[ic] + ca[ia]*cb[ib] + ca[ib]*cb[ia];
  }
  return (ps[oa+1]-ps[oa]) * (ps[ob+1]-ps[ob]) * 2;
}

static int
hpoly_asym_mul (const coef_t *ca, const coef_t *cb, coef_t *cc, const idx_t const* l, int oa, int ob, int ps[])
{
#ifdef TRACE
  printf("asym_mul oa=%d ob=%d \n", oa, ob);
#endif

  int iao = ps[oa], ibo = ps[ob];  // offsets for shifting to 0
  int ib_size = ps[ob+1] - ps[ob];
  for (idx_t ia=ps[oa]; ia < ps[oa+1]; ia++)
  for (idx_t ib=ps[ob]; ib < ps[ob+1]; ib++) {
    int ic = l[ hpoly_idx_rect(ia-iao, ib-ibo, ib_size) ];
    if (ic >= 0)
      cc[ic] = cc[ic] + ca[ia]*cb[ib];
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
  int *ps = dc->psto, hod = dc->mo / 2, comps = 0;
  const coef_t *ca  = a->coef, *cb  = b->coef;
  bit_t   nza = a->nz  ,  nzb = b->nz;
  coef_t *cc  = c->coef;

#ifdef _OPENMP
#pragma omp parallel for
  for (int i=2; i <= c->mo; i++) {
    int oc = !(i & 1) ? 1+i/2 : c->mo+1-i/2;
#else
  for (int oc=2; oc <= c->mo; oc++) {
#endif

    for (int j=1; j <= (oc-1)/2; ++j) {
      int oa = oc-j, ob = j;            // oa != ob
      const idx_t* l = dc->l[oa*hod + ob];

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
      if (bget(nza,hoc) && bget(nzb,hoc) ) {
        comps += hpoly_triang_mul(ca,cb,cc, dc->l[hoc*hod + hoc], hoc,ps);
        c->nz = bset(c->nz,oc);
      }
    }
  }
  return comps;
}

// == public functions

static int counter = 0;

tpsa_t*
tpsa_new(desc_t *d)
{
  tpsa_t *t = malloc(sizeof(tpsa_t) + d->nc * sizeof(coef_t));
#ifdef TRACE
  printf("new %p #%d from %p nc=%d\n", (void*)t, counter+1, (void*)d, d->nc);
#endif
  t->desc = d;
  t->id = ++counter;
  t->mo = 0;
  t->nz = 0;
  return t;
}

void
tpsa_delete(tpsa_t* t)
{
#ifdef TRACE
  printf("del %p #%d\n", (void*)t, t->id);
#endif
  free(t);
}

int // error code
tpsa_print(tpsa_t *t)
{
  desc_t *d = t->desc;
  printf("[ nz=%d; mo=%d; ", t->nz, t->mo);
  for (int i=0; i < d->nc; ++i)
    printf("%f ", t->coef[i]);
  printf(" ]\n");
  return 0;
}

int // error code
tpsa_setCoeff(tpsa_t *t, idx_t i, int o, coef_t v)
{
#ifdef TRACE
  printf("setCoeff\n");
#endif
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

  const coef_t *ca = a->coef, *cb = b->coef;
  coef_t *cc = c->coef;
  desc_t *dc = c->desc;

  c->nz = (ca[0] ? a->nz : 0) | (cb[0] ? b->nz : 0);
  c->mo = imin(a->mo + b->mo, dc->mo);

  cc[0] = ca[0]*cb[0];

  for (int i=1; i < dc->nc; i++)
    cc[i] = ca[0]*cb[i] + cb[0]*ca[i];

  int comps = (dc->nc-1) * 2 + 1;

  if (c->mo >= 2)
    comps += hpoly_mul(a, b, c);

  return comps;
}



