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

struct T {  // To, Tv; not needed here yet; better to keep them in lua
  int    size;
  mono_t mons[1];
  mono_t o[1];
  int    ps[1], pe[1];
};

struct desc {
  int     nc, mo;
  idx_t **l;
  idx_t   psto[];
};

struct tpsa { // warning: must be kept identical to LuaJit definition 
  desc_t *desc;
  int     mo;
  bit_t   nz;
  coef_t  coef[];
};

// == debug
static inline void
print_l(const idx_t const* l)
{
  printf("l=%p\n", l);
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

// == local functions

static void
hpoly_sym_mul (const coef_t *ca, const coef_t *cb, coef_t *cc, const idx_t const* l, int iao, int ibo)
{
#ifdef TRACE
  printf("sym_mul\n");
#endif
  int rs = l[0];
  for (idx_t ial=1; ial <       rs;     ial++)
  for (idx_t ibl=1; ibl <= l[ ial*rs ]; ibl++) {
    int ia = ial+iao;
    int ib = ibl+ibo;
    int ic = l[ ial*rs + ibl ];
    if (ic >= 0)
      cc[ic] = cc[ic] + ca[ia]*cb[ib] + ca[ib]*cb[ia];
  }
}

static void
hpoly_asym_mul (const coef_t *ca, const coef_t *cb, coef_t *cc, const idx_t const* l, int iao, int ibo)
{
#ifdef TRACE
  printf("asym_mul\n");
#endif
  int rs = l[0];
  for (int ial=1; ial <      rs;    ial++)
  for (int ibl=1; ibl <= l[ ial*rs ]; ibl++) {
    int ia = ial + iao;
    int ib = ibl + ibo;
    int ic = l[ ial*rs + ibl ];
    if (ic >= 0)
      cc[ic] = cc[ic] + ca[ia]*cb[ib];
  }
}

static void
hpoly_diag_mul (const coef_t* ca, const coef_t* cb, coef_t* cc, const idx_t const* l, int dio)
{
#ifdef TRACE
  printf("diag_mul\n");
#endif
  for (int il=1; il < l[0]; il++) {
    int isrc = il+dio;
    int idst = l[il];
    if (idst >= 0)
      cc[idst] = cc[idst] + ca[isrc]*cb[isrc];   
  }
}

static void
poly_mul2 (const tpsa_t *a, const tpsa_t *b, tpsa_t *c)
{
#ifdef TRACE
  printf("poly_mul2\n");
#endif
  desc_t *dc = c->desc;
  int *p = dc->psto, dmo = dc->mo;
  const coef_t *ca  = a->coef, *cb  = b->coef;
  bit_t   nza = a->nz  ,  nzb = b->nz;
  coef_t *cc  = c->coef;


  for (int oc=2; oc <= c->mo; oc++) {
    int ho = oc/2;
    for (int j=1; j <= ho; ++j) {
      int oa = oc-j, ob = j;
      const idx_t* l = dc->l[oa*dmo + ob];

      if (bget(nza,oa) && bget(nzb,ob) && bget(nza,ob) && bget(nzb,oa)) {
        hpoly_sym_mul(ca,cb,cc, l, p[oa]-1,p[ob]-1);
        c->nz = bset(c->nz,oc);
      }
      else if (bget(nza,oa) && bget(nzb,ob)) {
        hpoly_asym_mul(ca,cb,cc, l, p[oa]-1,p[ob]-1);
        c->nz = bset(c->nz,oc);
      }
      else if (bget(nza,ob) && bget(nzb,oa)) {
        hpoly_asym_mul(cb,ca,cc, l, p[oa]-1,p[ob]-1);
        c->nz = bset(c->nz,oc);
      }
    }
    if (oc%2 == 0)
      hpoly_diag_mul(ca,cb,cc, dc->l[ho*dmo + ho] ,p[ho]-1);
  }
}

// == public functions

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
  assert(i <= t->desc->nc);
  if (o > t->mo)
    t->mo = o;
  t->nz = bset(t->nz, o);
  t->coef[i] = v;
  return 0;
}

int // error code
tpsa_add(const tpsa_t *a, const tpsa_t *b, tpsa_t *c)
{
  return 0;
}

int // error code
tpsa_sub(const tpsa_t *a, const tpsa_t *b, tpsa_t *c)
{
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

  desc_t *dc = c->desc;
  const coef_t *ca = a->coef, *cb = b->coef;
  coef_t       *cc = c->coef;

  cc[0] = ca[0]*cb[0];

  for (int i=1; i <= dc->nc; i++)
    cc[i] = ca[0]*cb[i] + cb[0]*ca[i];

  c->nz = a->nz & b->nz;
  c->mo = imin(a->mo + b->mo, dc->mo);

  if (c->mo >= 2)
    poly_mul2(a, b, c); // TBC

  return 0;
}





