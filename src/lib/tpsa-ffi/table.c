#include <assert.h>
#include <stdio.h>
#include "mono.h"
#include "table.h"

int
tbl_by_var(table_t *t, int nv, int no, int nc, const mono_t a[nv], mono_t mons[nc])
{
  assert(a);
  assert(t && t->o && t->m);
  
  int mi = 0;
  mono_t m[nv];
  for (int i = 0; i < nv; ++i) m[i] = 0;
  do {
    mono_cpy(nv, m, mons);
    t->m[mi] = mons;
    t->o[mi] = mono_sum(nv, m);
    ++mi;
    mons += nv;
  } while (mono_nxt_by_var(nv, m, a, no));
  return mi;
}

int
tbl_by_ord(table_t *to, table_t *tv, int no, int nc)
{
  assert(to && tv && to != tv);
  assert(to->o && to->i && to->ps && to->m);
  assert(tv->o && tv->i           && to->m);
  
  // order 0
  to->m[0]  = tv->m[0];
  to->o[0]  = 0;
  to->ps[0] = 0;

  //orders 1..no
  int toi = 1;
  for (int o = 1; o <= no; ++o) {
    to->ps[o] = toi;
    for (int tvi = 1; tvi < nc; ++tvi)
      if (tv->o[tvi] == o) {
        to->m[toi] = tv->m[tvi];
        to->o[toi] = o;
        to->i[toi] = tvi;
        tv->i[tvi] = toi;
        ++toi;
      }
  }
  to->ps[no+1] = toi;
  return 0;
}

void
tbl_print(table_t *t, int nv, int no, int nc)
{
  for (int i = 0; i < nc; ++i) {
    printf("(%d) ", i);
    mono_print(nv, t->m[i]);
    printf(" o=%2d i=%3d\n", t->o[i], t->i[i]);
  }
  if (t->ps) {
    printf("ps = [ ");
    for (int o = 0; o <= no; ++o)
      printf("%d ", t->ps[o]);
    printf("]\n");
  }
}

int
find_index(int n, const table_t *Tv, const mono_t a[n], int start, int stop)
{
  for (int i = start; i < stop; ++i)
    if (mono_equ(n,Tv->m[i],a)) return i;

  // error
  printf("monomial not found in table: ");
  mono_print(n,a);
  assert(NULL);
}

int
tbl_index_H(const desc_t *d, const mono_t a[])
{
  int s = 0, I = 0, cols = d->mo + 2;
  const int *H = d->H;
  for (int i = d->nv - 1; i >= 0; --i) {
    I += H[(i+1)*cols + s+a[i]] - H[(i+1)*cols + s];
    s += a[i];
  }
  return I;
}

void
solve_H(desc_t *d)
{
  int nv = d->nv, cols = d->mo + 2;
  mono_t sa[nv], b[nv], *a = d->a;
  mono_acc(nv,a,sa);

  // solve system of equations
  for (int i = nv-2; i >= 1; --i)  // variables
    for (int j = a[i]+2; j <= (sa[i] < d->mo ? sa[i] : d->mo); j++) { // orders
      mono_nxt_by_unk(nv,a,i,j,b);
      idx_t idx0 = tbl_index_H(d,b);
      idx_t idx1 = find_index(nv,d->Tv,b,idx0,d->nc);
      d->H[(i+1)*cols + j] = idx1 - idx0;
    }
}

void
tbl_build_H(desc_t *d)
{
  assert(d && d->a && d->Tv && d->To && d->H);
  assert(d->nv != 0 && d->mo != 0 && d->nc != 0);

  // minimal constants for 1st row
  int nv = d->nv, mo = d->mo, cols = d->mo + 2;
  idx_t *H = d->H;
  mono_t **Tv = d->Tv->m;
  for (int j=0; j <= mo+1; ++j)
    H[1*cols + j] = j;

  // remaining rows
  for (int i = 2; i <= nv; ++i) {  // variables
    H[i*cols + 0] = 0;
    int crtPos = 1;

    // initial congruence from Tv
    for (int j = 1; j < d->nc; j++) { // monomials
      if (Tv[j][i-1] != Tv[j-1][i-1]) {
        H[i*cols + crtPos] = j;
        crtPos++;
        if (Tv[j][i-1] == 0) break;
      }
    }

    // complete row with zeros
    while(crtPos <= mo+1) H[i*cols + crtPos] = 0, crtPos++;
  }

  // close congruence of the last var
  H[nv*cols + d->a[nv-1]+1] = d->nc;

  solve_H(d);

#ifdef TRACE
  printf("H = {\n");
  tbl_print_H(d);
#endif
}

void
tbl_print_H(const desc_t *d)
{
  assert(d && d->H);
  int cols = d->mo + 2;
  for (int i = 0; i <= d->nv; ++i) {
    for (int j = 0; j <= d->mo + 1; ++j)
      printf("%2d ", d->H[i*cols + j]);
    printf("\n");
  }
}


