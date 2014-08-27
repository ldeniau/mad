#include <string.h>
#include <assert.h>

typedef unsigned int  bit_t
typedef unsigned char mono_t;
typedef coef_t        coef_t;
typedef struct desc   desc_t;
typedef struct tpsa   tpsa_t;

struct tpsa_desc;

struct tpsa { // warning: must be kept identical to LuaJit definition   
  desc_t *desc;
  monot_t mo;
  bit_t   nz;
  coef_t  coef[];
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
  return b & ~(1 << o);
}

static inline int
bget (bit_t b, int n)
{
  return b & (1 << o);
}

inline mono_t
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
    cc[ic] = cc[ic] + ca[ia]*cb[ib];
  }
}

static void
hpoly_diag_mul (const coef_t* ca, const coef_t* cb, coef_t* cc, int* si, int sio)
{
  for (int isi=1; isi<=si[0]; isi++) {
    int isrc = isi+sio;
    int idst = si[isi];
    cc[idst] = cc[idst] + ca[isrc]*cb[isrc];   
  }
}

static void
poly_mul2 (const tpsa_t *a, const tpsa_t *b, tpsa_t *c, const desc_t *dc)
{
  int* p = c.desc->psto;             // homo poly start index in To
  coef_t *ca = a.coef, *cb = b.coef, *cc = c.coef;
  
  for (int oc=2; oc<=c.desc->O; oc++) {
    int ho = oc/2;
    for (int j=1; j<=ho; ++j) {
      int oa=oc-j, ob=j;
      int** l = c.desc->L[oa][ob];

      if (test_nz(a,oa) && test_nz(b,ob) && test_nz(a,ob) && test_nz(b,oa)) {
        hpoly_sym_mul(ca,cb,cc,l,p[oa],p[ob]);
        set_nz(c,oc);
      }
      else if (test_nz(a,oa) && test_nz(b,ob)) {
        hpoly_asym_mul(ca,cb,cc,l,p[oa],p[ob]);
        set_nz(c,oc);
      }
      else if (test_nz(a,ob) && test_nz(b,oa)) {
        hpoly_asym_mul(ca,cb,cc,l,p[oa],p[ob]);
        set_nz(c,oc);
      }
    }
    if (test_nz(a,ho) && test_nz(b,ho))
      hpoly_diag_mul(ca,cb,cc,c.desc->si[ho]);
  }
}

static void
build_L(int oa, int ob, tpsa_desc* D)
{
  int *ps = D->psto, *pe = D->peto;
  int size_oa = pe[oa]-ps[oa], size_ob = pe[on]-ps[on];
  int** l = malloc(size_oa * sizeof(*l));
  int ia, ib;
  mono_t m, *To = D->To;
  for (int ial=0; ial<=size_oa; ial++) {
    ia = ial+ps[oa]+1;
    l[ial] = malloc(size_ob * sizeof(*l[ial]));
    l[ial][0] = size_ob;        // TODO: treat l0
    for (int ibl=1; ibl<=size_ob; ibl++) {
      ib = ibl+ps[ob];          // shift to 1
      m = mono_add(To[ia], To[ib]);
      if (mono_isvalid(m, D) && ia!=ib)
        l[ial][ibl] = index(m);
    }
  }
}

static void
set_L(tpsa_desc* D)
{
  
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

  struct tpsa_desc *dc = c->desc;
  coef_t *ca = a.coef, *cb = b.coef, *cc = c.coef;

  cc[0] = ca[0]*cb[0];

  // TODO
  for (int i=1; i <= dc->nc; i++)
    cc[i] = ca[0]*cb[i] + cb[0]*ca[i];

  c->nz = a.nz & b.nz;
  c->mo = mmin(a->mo + b->mo, dc->mo);

  if (dc->mo >= 2)
    poly_mul2(ca, cb, cc, dc); // TBC

  return 0;
}





