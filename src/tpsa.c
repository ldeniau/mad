#include <string.h>

#define MAX_NC 1000        // varies in luajit ffi

typedef char mono_t;

typedef struct tpsa {
  struct tpsa_desc *desc;
  unsigned char mo;
  unsigned int nz;       // used as bit array
  double coef[MAX_NC];
} tpsa_t;

tpsa_t* new(const tpsa_t* a) {
  tpsa_t* r = malloc(sizeof(*a));
  return memcpy(r, a, sizeof(a));
}


void mul(const tpsa_t* a, const tpsa_t* b, tpsa_t* c) {
  double *ca = a.coef, *cb = b.coef, *cc = c.coef;
  cc[0] = ca[0]*cb[0];
  for (int  i=1, i<=c.desc->NC; i++)  // should stop early? Berz doesn't
    cc[i] = ca[0]*cb[i] + cb[0]*ca[i];
  c.nz = a.nz&b.nz;
  c.mo = min(a.mo+b.mo, c.desc->O);

  if (c.desc->O >= 2)
    poly_mul2(ca, cb, cc);
}

void poly_mul2(tpsa_t a, tpsa_t b, tpsa_t c) {
  int* p = c.desc->psto;             // homo poly start index in To
  double *ca = a.coef, *cb = b.coef, *cc = c.coef;
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

void hpoly_sym_mul(double* ca, double* cb, double* cc,
                   int** l, int iao, int ibo) {
  int ia, ib, ic;
  for (int ial=1; ial<=l[0][0]; ial++)
    for (int ibl=1; ibl<=l[ial][0]; ibl++) {
      ia = ial+iao; ib = ibl+ibo; ic = l[ial][ibl];
      cc[ic] = cc[ic] + ca[ia]*cb[ib] + ca[ib]*cb[ia];
    }
}

void hpoly_asym_mul(double* ca, double* cb, double* cc,
                    int** l, int iao, int ibo) {
  int ia, ib, ic;
  for (int ial=1; ial<=l[0][0]; ial++)
    for (int ibl=1; ibl<=l[ial][0]; ibl++) {
      ia = ial+iao; ib = ibl+ibo; ic = l[ial][ibl];
      cc[ic] = cc[ic] + ca[ia]*cb[ib];
    }
}

void hpoly_diag_mul(double* ca, double* cb, double* cc, int* si, int sio) {
  int isrc, idst;
  for (int isi=1; isi<=si[0]; isi++) {
    isrc = isi+sio;
    idst = si[isi];
    cc[idst] = cc[idst] + ca[isrc]*cb[isrc];   
  }
}

void build_L(int oa, int ob, tpsa_desc* D) {
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

void set_L(tpsa_desc* D) {
  
}


// ========== HELPERS ==========
void inline set_nz(tpsa_t t, int o) {
  t.nz |= (1<<o);
}

void inline clear_nz(tpsa_t t, int o) {
  t.nz &= ~(1<<o);
}

int inline test_nz(const tpsa_t t, int o) {
  return t.nz & (1<<o);
}

int inline min(const int a, const int b) {
  return a<b ? a : b;
}




