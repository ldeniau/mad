#ifndef MAD_MONO_H
#define MAD_MONO_H

#include <assert.h>
#include <stdio.h>
// --- types -------------------------------------------------------------------

typedef unsigned char ord_t;

// --- interface ---------------------------------------------------------------

static inline ord_t
mmin (ord_t a, ord_t b)
{
  return a<b ? a : b;
}

static inline void
mono_clr(int n, ord_t m[n])
{
  assert(m);
  for (int i=0; i < n; ++i) m[i] = 0;
}

static inline ord_t
mono_sum(int n, const ord_t m[n])
{
  assert(m);
  ord_t s = 0;
  for (int i=0; i < n; ++i)
    s += m[i];
  return s;
}

static inline void
mono_cpy(int n, const ord_t src[n], ord_t dst[n])
{
  assert(src && dst);
  for (int i = 0; i < n; ++i) dst[i] = src[i];
}

static inline void
mono_acc(int n, const ord_t a[n], ord_t r[n])
{
  mono_cpy(n,a,r);
  for (int i = n-2; i >= 0; --i)
    r[i] += r[i+1];
}

static inline int
mono_equ(const int n, const ord_t a[n], const ord_t b[n])
{
  assert(a && b);
  for (int i = 0; i < n; ++i)
    if (a[i] != b[i]) return 0;
  return 1;
}

static inline int
mono_geq(const int n, const ord_t a[n], const ord_t b[n])
{
  // partial order relation ({3,0,0} <= {1,1,0})
  assert(a && b);
  for (int i = n - 1; i >= 0; --i)
    if      (a[i] < b[i]) return 0;
    else if (a[i] > b[i]) return 1;
  return 1;
}

static inline int
mono_elem_leq(int n, const ord_t a[n], const ord_t b[n])
{
  assert(a && b);
  for (int i=0; i < n; ++i)
    if (a[i] > b[i])
      return 0;
  return 1;
}

static inline void
mono_add(int n, const ord_t a[n], const ord_t b[n], ord_t r[n])
{
  assert(a && b && r);
  for (int i = 0; i < n; ++i) r[i] = a[i] + b[i];
}

static inline int
mono_isvalid(int n, const ord_t m[n], const ord_t a[n], const ord_t o)
{
  return mono_sum(n, m) <= o && mono_elem_leq(n, m, a);
}

static inline void
mono_print(int n, const ord_t m[n])
{
  assert(m);
  printf("[ ");
  for (int i=0; i < n; ++i)
    printf("%d ", (int)m[i]);
  printf("]");
}

// -----------------------------------------------------------------------------

#endif
