#ifndef MAD_SSE_AVX_H
#define MAD_SSE_AVX_H

#include <immintrin.h>

// char
#define SSE_CSIZ 16
#define SSE_CMSK            (SSE_CSIZ-1)
#define SSE_CRND(n) ((n) & ~(SSE_CSIZ-1))
#define SSE_CMOD(n) ((n) &  (SSE_CSIZ-1))

// int
#define SSE_ISIZ 4
#define SSE_IMSK            (SSE_ISIZ-1)
#define SSE_IRND(n) ((n) & ~(SSE_ISIZ-1))
#define SSE_IMOD(n) ((n) &  (SSE_ISIZ-1))

// double
#define SSE_DSIZ 2
#define SSE_DMSK            (SSE_DSIZ-1)
#define SSE_DRND(n) ((n) & ~(SSE_DSIZ-1))
#define SSE_DMOD(n) ((n) &  (SSE_DSIZ-1))

#endif