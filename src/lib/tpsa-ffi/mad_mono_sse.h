#ifndef MAD_MONO_SSE_H
#ifdef __SSE2__
#include <immintrin.h>

// Warning: untested code!
// Not faster than compiler version for remaing 16 bytes
// Could be faster if monomials are always k*16 bytes long, i.e. padded with zeros
// Could be even faster (?) if monomials are always 16 bytes aligned

#undef mono_add
#undef mono_sum
#undef mono_leq
#undef mono_isvalid

#define mono_add     mono_add_sse2
#define mono_sum     mono_sum_sse2
#define mono_leq     mono_leq_sse2
#define mono_isvalid mono_isvalid_sse2

static inline void
mono_add_sse2(int n, const ord_t a[n], const ord_t b[n], ord_t r[n])
{
  assert(a && b && r);
  __m128i ra, rb, rr;
  int i;

  for (i=0; i < (n & ~7); i+=16) {
    ra = _mm_loadu_si128((__m128i*)&a[i]);
    rb = _mm_loadu_si128((__m128i*)&b[i]);
    rr = _mm_adds_epi8(ra,rb);
    _mm_storeu_si128((__m128i*)&r[i],rr);
  }

  for (int j=0; j < (n & 7); j++)
    r[i+j] = a[i+j] + b[i+j];
}

static inline int
mono_sum_sse2(int n, const ord_t a[n])
{
  assert(a);
  __m128i ra, zero = _mm_setzero_si128();
  int i, s = 0;

  for (i=0; i < (n & ~7); i+=16) {
    ra = _mm_sad_epu8(_mm_loadu_si128((__m128i*)&a[i]), zero);
    s += _mm_cvtsi128_si32(_mm_srli_si128(ra,8)) + _mm_cvtsi128_si32(ra);
  }

  for (int j=0; j < (n & 7); j++) s += a[i+j];
  return s;
}

static inline int
mono_leq_sse2(int n, const ord_t a[n], const ord_t b[n])
{
  assert(a && b);
  __m128i ra, rb, rr;
  int i;

  for (i=0; i < (n & ~7); i+=16) {
    ra = _mm_loadu_si128((__m128i*)&a[i]);
    rb = _mm_loadu_si128((__m128i*)&b[i]);
    rr = _mm_cmpgt_epi8(ra,rb);
    if (_mm_movemask_epi8(rr)) return 0;
  }

  for (int j=0; j < (n & 7); j++)
    if (a[i+j] > b[i+j]) return 0;

  return 1;
}

static inline int
mono_isvalid_sse2(int n, const ord_t a[n], const ord_t m[n], int o)
{
  return mono_sum_sse2(n, m) <= o && mono_leq_sse2(n, m, a);
}

#endif
#endif
