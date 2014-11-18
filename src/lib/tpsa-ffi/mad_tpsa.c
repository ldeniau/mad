#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include "mad_tpsa.h"
#include "tpsa_desc.tc"
//#include "mem_alloc.h"

// #define TRACE

typedef unsigned int  bit_t;

#define T struct tpsa
#define D struct tpsa_desc

struct tpsa { // warning: must be kept identical to LuaJit definition
  D      *desc;
  int     mo;
  bit_t   nz;
  num_t   coef[];
};

struct compose_ctx {
  int sa;
  const T **ma, **mb;
        T **mc, **tmps;
  D *da;
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

// --- HELPERS ----------------------------------------------------------------

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

static inline void
swap (T **a, T **b)
{
  T *tmp = *a;
  *a = *b;
  *b = tmp;
}

// --- LOCAL FUNCTIONS --------------------------------------------------------

static inline int
hpoly_triang_mul(const num_t *ca, const num_t *cb, num_t *cc, const idx_t const* l, int oa, int pi[])
{
#ifdef TRACE
  printf("triang_mul oa=%d ob=%d\n", oa, oa);
#endif
  int iao = pi[oa], ibo = pi[oa];  // offsets for shifting to 0
  int l_size = (pi[oa+1]-pi[oa]) * (pi[oa+1]-pi[oa] + 1) / 2, oc = oa + oa;
  (void)oc; (void)l_size;  // avoid warning when compiling without assert

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
  (void)oc; (void)l_size;  // avoid warning when compiling without assert

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
  (void)oc; (void)l_size;  // avoid warning when compiling without assert

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
      int oa = oc-j, ob = j;            // oa > ob
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

    if (! (oc & 1)) {  // even oc, triang matrix
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

// --- PUBLIC FUNCTIONS -------------------------------------------------------

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

void
mad_tpsa_add(const T *a, const T *b, T *c)
{
#ifdef TRACE
  printf("tpsa_add\n");
#endif
  assert(a && b && c);
  assert(a->desc == b->desc && a->desc == c->desc);
  c->nz = a->nz | b->nz;
  c->mo = a->mo > b->mo ? a->mo : b->mo;  // max(amo,bmo)

  const num_t *ca, *cb;
  int len_a, len_b;
  if (a->mo <= b->mo) {
    ca = a->coef;
    cb = b->coef;
    len_a = c->desc->hpoly_To_idx[a->mo + 1];
    len_b = c->desc->hpoly_To_idx[b->mo + 1];
  }
  else {  // swap: 'ca' is the shortest
    ca = b->coef;
    cb = a->coef;
    len_a = c->desc->hpoly_To_idx[b->mo + 1];
    len_b = c->desc->hpoly_To_idx[a->mo + 1];
  }

  for (int i = 0    ; i < len_a; ++i)  c->coef[i] = ca[i] + cb[i];
  for (int i = len_a; i < len_b; ++i)  c->coef[i] =         cb[i];
}

void
mad_tpsa_sub(const T *a, const T *b, T *c)
{
#ifdef TRACE
  printf("tpsa_sub\n");
#endif
  assert(a && b && c);
  assert(a->desc == b->desc && a->desc == c->desc);
  c->nz = a->nz | b->nz;
  c->mo = a->mo > b->mo ? a->mo : b->mo;  // max(amo,bmo)

  const num_t *ca = a->coef, *cb = b->coef;
  int len_a = c->desc->hpoly_To_idx[a->mo + 1],
      len_b = c->desc->hpoly_To_idx[b->mo + 1];

    for (int i = 0    ; i < imin(len_a,len_b); ++i) c->coef[i] = ca[i] - cb[i];
  if (len_a <= len_b)
    for (int i = len_a; i <            len_b ; ++i) c->coef[i] =       - cb[i];
  else
    for (int i = len_b; i <      len_a       ; ++i) c->coef[i] = ca[i]        ;
}

void
mad_tpsa_mul(const T *a, const T *b, T *c)
{
#ifdef TRACE
  printf("tpsa_mul\n");
#endif
  assert(a && b && c);
  assert(a->desc == b->desc && a->desc == c->desc);

  if (a->mo > b->mo) {  // swap so that a is the shortest
    const T *tmp = a;
    a = b;
    b = tmp;
  }

  const num_t *ca = a->coef, *cb = b->coef;
  num_t *cc = c->coef;
  D *dc = c->desc;

  c->nz = (ca[0] ? b->nz : 0) | (cb[0] ? a->nz : 0);
  c->mo = imin(a->mo + b->mo, dc->mo);

  cc[0] = ca[0]*cb[0];

  int len_a = dc->hpoly_To_idx[a->mo+1],
      len_b = dc->hpoly_To_idx[b->mo+1],
      len_c = dc->hpoly_To_idx[c->mo+1],
      i = 1;
  for (; i < len_a; i++) cc[i] = ca[0]*cb[i] + cb[0]*ca[i];
  for (; i < len_b; i++) cc[i] = ca[0]*cb[i];
  for (; i < len_c; i++) cc[i] = 0;

  int comps = (dc->hpoly_To_idx[c->mo+1] - 1) * 2 - 1;

  if (c->mo >= 2)
    comps += hpoly_mul(a, b, c);

//return comps;
}

void
mad_tpsa_mulc(const T *a, T *r, num_t v)
{
#ifdef TRACE
  printf("tpsa_mul_constant %lf\n", v);
#endif
  assert(a && r);
  assert(a->desc == r->desc);

  r->nz = a->nz;
  r->mo = a->mo;
  for (int i = 0; i < a->desc->hpoly_To_idx[a->mo + 1]; ++i)
    r->coef[i] = a->coef[i] * v;
}

void
mad_tpsa_pow(const T *a, T *orig_res, int p)
{
#ifdef TRACE
  printf("tpsa_pow %p to %d\n", (void*)a, p);
#endif
  assert(a && orig_res);
  assert(a->desc == orig_res->desc);
  assert(p >= 0);

  if (p == 0) {
    mad_tpsa_clean(orig_res);
    mad_tpsa_seti(orig_res, 0, 1);
    return;
  }
  if (p == 1) {
    mad_tpsa_copy(a, orig_res);
    return;
  }

  // init: base = a, r = 1, tmp
  T *base = mad_tpsa_new(a), *r = orig_res, *tmp_res = mad_tpsa_new(a);
  mad_tpsa_copy(a, base);
  mad_tpsa_clean(r);
  mad_tpsa_seti(r, 0, 1);

  while(p > 1) {
    if (p & 1) {
      mad_tpsa_mul(base, r, tmp_res);
      swap(&r, &tmp_res);
    }
    mad_tpsa_mul(base, base, tmp_res);
    swap(&base, &tmp_res);
    p /= 2;
  }
  mad_tpsa_mul(base, r, tmp_res);

  // save result and dealloc
  mad_tpsa_copy(tmp_res, orig_res);
  if (base    != orig_res) mad_tpsa_del(base);
  if (r       != orig_res) mad_tpsa_del(r);
  if (tmp_res != orig_res) mad_tpsa_del(tmp_res);
}

static inline void
check_compose(int sa, const T *ma[], int sb, const T *mb[], int sc, T *mc[])
{
  assert(ma && mb && mc);
  assert(sa && sb && sc);
  assert(sa == sc);
  assert(sb == ma[0]->desc->nv);
  for (int i = 1; i < sa; ++i) {
    assert(ma[i]->desc == ma[i-1]->desc);
    assert(ma[i]->desc == mc[i]->desc);
  }
  for (int i = 1; i < sb; ++i)
    assert(mb[i]->desc == mb[i-1]->desc);
}

static inline void
compose(int pos, ord_t o, ord_t curr_mono[], const struct compose_ctx *ctx)
{
  D *da = ctx->da;
  for(  ; pos < da->nv; ++pos) {
    curr_mono[pos]++;
    if (desc_mono_isvalid(da, da->nv, curr_mono)) {
      mad_tpsa_mul(ctx->tmps[o], ctx->mb[pos], ctx->tmps[o+1]);
      compose(pos, o+1, curr_mono, ctx);
    }
    curr_mono[pos]--;
  }
  int idx = desc_get_idx(da, da->nv, curr_mono);
  double coef_val;
  for (int i = 0; i < ctx->sa; ++i) {
    if ((coef_val = ctx->ma[i]->coef[idx])) {
      mad_tpsa_mulc(ctx->tmps[o], ctx->tmps[-1], coef_val);
      mad_tpsa_add(ctx->mc[i], ctx->tmps[-1], ctx->mc[i]);
    }
  }
}

void
mad_tpsa_compose(int sa, const T *ma[], int sb, const T *mb[], int sc, T *mc[])
{
#ifdef TRACE
  printf("tpsa_compose\n");
#endif
  check_compose(sa, ma, sb, mb, sc, mc);

  D *da = ma[0]->desc;

  ord_t mono[da->nv];
  T *tmps[da->mo+2];
  for (int v = 0; v < da->nv  ; ++v) mono[v] = 0;
  for (int o = 0; o < da->mo+2; ++o) tmps[o] = mad_tpsa_newd(da);
  mad_tpsa_seti(tmps[1], 0, 1.0);

  const struct compose_ctx ctx = {sa, ma, mb, mc, tmps+1, da};

  compose(0, 0, mono, &ctx);

  for (int o = 0; o < da->mo+2; ++o) mad_tpsa_del(tmps[o]);
}

void
mad_tpsa_compose_slow(int sa, const T *ma[], int sb, const T *mb[], int sc, T *mc[])
{
#ifdef TRACE
  printf("tpsa_compose\n");
#endif
  assert(ma && mb && mc);
  assert(ma[0]->desc->nv == sb);
  (void)sc;

  D *desc_a = ma[0]->desc;
  ord_t *curr_mono;
  T *curr_build = mad_tpsa_new(ma[0]), *tmp_res = mad_tpsa_new(ma[0]);
  int nv = desc_a->nv, coef_lim;
  for (int ia = 0; ia < sa; ++ia) {
    coef_lim = desc_a->hpoly_To_idx[ma[ia]->mo + 1];

    for (int mono_idx = 0; mono_idx < coef_lim; ++mono_idx) {
      curr_mono = desc_a->To[mono_idx];

      mad_tpsa_clean(curr_build);
      num_t curr_coef = mad_tpsa_geti(ma[ia], mono_idx);
      if (curr_coef == 0)
        continue;

      mad_tpsa_seti(curr_build, 0, curr_coef);
      for (int cmi = 0; cmi < nv; ++cmi)
        for (ord_t o = 0; o < curr_mono[cmi]; ++o) { // pow
          mad_tpsa_mul(curr_build, mb[cmi], tmp_res);
          mad_tpsa_copy(tmp_res, curr_build);
        }

      mad_tpsa_add(mc[ia], curr_build, tmp_res);
      mad_tpsa_copy(tmp_res, mc[ia]);
    }
  }
}

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

#undef T
#undef D
#undef TRACE
