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

void
tbl_build_H(desc_t *d, int nv)
{
  
}


