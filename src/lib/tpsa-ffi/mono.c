#include "mono.h"

#include <string.h>
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

//typedef unsigned char mono_t;
//typedef struct table table_t;
struct table {
  int     *o, *i, *ps;
  mono_t **m;
};

void
mono_clr(int n, mono_t m[n])
{
  assert(m);
  for (int i=0; i < n; ++i) m[i] = 0;
}

void
mono_cpy(int n, const mono_t src[n], mono_t dst[n])
{
  assert(src && dst);
  for (int i = 0; i < n; ++i) dst[i] = src[i];
}

int
mono_sum(int n, const mono_t m[n])
{
  assert(m);
  int s = 0;
  for (int i=0; i < n; ++i)
    s += m[i];
  return s;
}

int
mono_elem_leq(int n, const mono_t a[n], const mono_t b[n])
{
  assert(a && b);
  for (int i=0; i < n; ++i)
    if (a[i] > b[i])
      return 0;
  return 1;
}

int
mono_isvalid(int n, const mono_t m[n], const mono_t a[n], const int o)
{
  return mono_sum(n, m) <= o && mono_elem_leq(n, m, a);
}

int
mono_nxt_by_var(int n, mono_t m[n], const mono_t a[n], const int o)
{
  assert(m);
  for (int i=0; i < n; ++i) {
    ++m[i];
    if (mono_isvalid(n, m, a, o))
      return 1;
    m[i] = 0;
  }
  return 0;
}

void
mono_print(int n, const mono_t m[n])
{
  assert(m);
  printf("[ ");
  for (int i=0; i < n; ++i)
    printf("%d ", (int)m[i]);
  printf("]");
}

void
mono_add(int n, const mono_t a[n], const mono_t b[n], mono_t r[n])
{
  assert(a && b && r);
  for (int i = 0; i < n; ++i) r[i] = a[i] + b[i];
}

int
tbl_by_var(table_t* t, int nv, int no, int nc, const mono_t a[nv], mono_t mons[nc])
{
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
  return 0;
}

