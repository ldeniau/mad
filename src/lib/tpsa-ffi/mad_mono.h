#ifndef MAD_MONO_H
#define MAD_MONO_H

// --- types -------------------------------------------------------------------

typedef unsigned char ord_t;

// --- interface ---------------------------------------------------------------

static void  mono_set     (int n, ord_t a[n], ord_t v);
static int   mono_sum     (int n, const ord_t a[n]);
static void  mono_cpy     (int n, const ord_t a[n],       ord_t r[n]);
static int   mono_equ     (int n, const ord_t a[n], const ord_t b[n]);
static int   mono_rcmp    (int n, const ord_t a[n], const ord_t b[n]);
static int   mono_leq     (int n, const ord_t a[n], const ord_t b[n]);
static void  mono_add     (int n, const ord_t a[n], const ord_t b[n], ord_t r[n]);
static void  mono_print   (int n, const ord_t a[n]);

// -----------------------------------------------------------------------------
// --- implementation ----------------------------------------------------------

#include <assert.h>

static inline void
mono_set(int n, ord_t a[n], ord_t v)
{
  assert(a);
  for (int i=0; i < n; ++i) a[i] = v;
}

static inline int
mono_sum(int n, const ord_t a[n])
{
  assert(a);
  int s = 0;
  for (int i=0; i < n; ++i) s += a[i];
  return s;
}

static inline void
mono_cpy(int n, const ord_t a[n], ord_t r[n])
{
  assert(a && r);
  for (int i = 0; i < n; ++i) r[i] = a[i];
}

static inline int
mono_equ(int n, const ord_t a[n], const ord_t b[n])
{
  assert(a && b);
  for (int i = 0; i < n; ++i)
    if (a[i] != b[i]) return 0;
  return 1;
}

static inline int
mono_rcmp(int n, const ord_t a[n], const ord_t b[n])
{
  assert(a);
  assert(b);
  for (int i = n - 1; i >= 0; --i)
    if (a[i] != b[i])
      return a[i] - b[i];
  return 0;
}

static inline int
mono_leq(int n, const ord_t a[n], const ord_t b[n])
{
  assert(a && b);
  for (int i=0; i < n; ++i)
    if (a[i] > b[i]) return 0;
  return 1;
}

static inline void
mono_add(int n, const ord_t a[n], const ord_t b[n], ord_t r[n])
{
  assert(a && b && r);
  for (int i = 0; i < n; ++i) r[i] = a[i] + b[i];
}

#include <stdio.h>

static inline void
mono_print(int n, const ord_t m[n])
{
  assert(m);
  printf("[ ");
  for (int i=0; i < n; ++i)
    printf("%d ", (int)m[i]);
  printf("]");
}

// --- SSE2 implementation -----------------------------------------------------

// Comment the following include to disable SSE/AVX optimization
#include "mad_mono_sse.h"
#include "mad_mono_avx.h"

// -----------------------------------------------------------------------------
#endif
