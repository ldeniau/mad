#include "mono.h"

#include <string.h>
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

//typedef unsigned char mono_t;

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
mono_equ(const int n, const mono_t a[n], const mono_t b[n])
{
  for (int i = 0; i < n; ++i)
    if (a[i] != b[i]) return 0;
  return 1;
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

void
mono_acc(int n, const mono_t a[n], mono_t r[n])
{
  mono_cpy(n,a,r);
  for (int i = n-2; i >= 0; --i)
    r[i] += r[i+1];
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
mono_nxt_by_unk(int n, const mono_t a[n], int i, int j, mono_t m[n])
{
  assert(a && m);
  mono_clr(n,m);
  for (int k=i; k < n; ++k) {
    m[k] = a[k];
    j -= a[k];
    if (j <= 0) {
      if (j < 0) m[k] += j;
      break;
    }
  }
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


