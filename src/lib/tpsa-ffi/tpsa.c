#include <string.h>
#include <stdlib.h>
#include <assert.h>

typedef unsigned int  bit_t;
typedef unsigned char mono_t;
typedef int           idx_t;
typedef double        coef_t;
typedef struct desc   desc_t;
typedef struct tpsa   tpsa_t;

struct T {  // To, Tv; not needed here yet; better to keep them in lua
  size_t size;
  mono_t mons[1];
  mono_t o[1];
  size_t ps[1], pe[1];
};

struct desc {
  int nc, o;
  int l[1];
  int *di;
};

struct tpsa { // warning: must be kept identical to LuaJit definition 
  desc_t *desc;
  mono_t  mo;
  bit_t   nz;
  coef_t  coef[1];
};

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

static inline mono_t
mmin (mono_t a, mono_t b)
{
  return a<b ? a : b;
}

// == local functions

static void
hpoly_sym_mul (const coef_t *ca, const coef_t *cb, coef_t *cc, int const* const* l, int iao, int ibo)
{
  for (int ial=1; ial <= l[ 0 ][0]; ial++)
  for (int ibl=1; ibl <= l[ial][0]; ibl++) {
    int ia = ial+iao;
    int ib = ibl+ibo;
    int ic = l[ial][ibl];
    if (ic >= 0)
      cc[ic] = cc[ic] + ca[ia]*cb[ib] + ca[ib]*cb[ia];
  }
}

static void
hpoly_asym_mul (const coef_t *ca, const coef_t *cb, coef_t *cc, int const* const* l, int iao, int ibo)
{
  for (int ial=1; ial<=l[ 0 ][0]; ial++)
  for (int ibl=1; ibl<=l[ial][0]; ibl++) {
    int ia = ial + iao;
    int ib = ibl + ibo;
    int ic = l[ial][ibl];
    if (ic >= 0)
      cc[ic] = cc[ic] + ca[ia]*cb[ib];
  }
}

static void
hpoly_diag_mul (const coef_t* ca, const coef_t* cb, coef_t* cc, int* di, int dio)
{
  for (int idi=1; idi <= di[0]; idi++) {
    int isrc = idi+dio;
    int idst = di[idi];
    if (idst >= 0)
      cc[idst] = cc[idst] + ca[isrc]*cb[isrc];   
  }
}

static void
poly_mul2 (const tpsa_t *a, const tpsa_t *b, tpsa_t *c)
{
  desc_t *dc = c->desc;
  size_t *p = dc->to.ps;             // homo poly start index in To
  bit_t nza = a->nz, nzb = b->nz, nzc = c->nz;
  const coef_t *ca = a->coef, *cb = b->coef;
  coef_t       *cc = c->coef;

  for (int oc=2; oc <= dc->o; oc++) {
    int ho = oc/2;
    for (int j=1; j <= ho; ++j) {
      int oa = oc-j, ob = j;
      //size_t (*l)[] = dc->l[oa][ob];  // TODO: choose best decl
      const int* const* l = dc->l[oa][ob];

      if (bget(nza,oa) && bget(nzb,ob) && bget(nza,ob) && bget(nzb,oa)) {
        hpoly_sym_mul(ca,cb,cc,l,p[oa],p[ob]);
        bset(nzc,oc);
      }
      else if (bget(nza,oa) && bget(nzb,ob)) {
        hpoly_asym_mul(ca,cb,cc,l,p[oa],p[ob]);
        bset(nzc,oc);
      }
      else if (bget(nza,ob) && bget(nzb,oa)) {
        hpoly_asym_mul(ca,cb,cc,l,p[oa],p[ob]);
        bset(nzc,oc);
      }
    }
    if (bget(nza,ho) && bget(nzb,ho))
      hpoly_diag_mul(ca,cb,cc,dc->di[ho],p[ho]);
  }
}

// == public functions

int // error code
tpsa_add(const tpsa_t* a, const tpsa_t* b, tpsa_t* c)
{
  return 0;
}

int // error code
tpsa_sub(const tpsa_t* a, const tpsa_t* b, tpsa_t* c)
{
  return 0;
}

int // error code
tpsa_mul(const tpsa_t* a, const tpsa_t* b, tpsa_t* c)
{
  assert(a && b && c);
  assert(a->desc == b->desc && a->desc == c->desc);

  desc_t *dc = c->desc;
  const coef_t *ca = a->coef, *cb = b->coef;
  coef_t       *cc = c->coef;

  cc[0] = ca[0]*cb[0];

  for (int i=1; i <= dc->nc; i++)
    cc[i] = ca[0]*cb[i] + cb[0]*ca[i];

  c->nz = a->nz & b->nz;
  c->mo = mmin(a->mo + b->mo, dc->o);

  if (dc->o >= 2)
    poly_mul2(a, b, c); // TBC

  return 0;
}





