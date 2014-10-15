#ifndef MAD_MONO_AVX_H
#ifdef __AVX2__ // minimum requirement
#include "mad_sse_avx.h"

/* TODO

#undef mono_add
#undef mono_sum
#undef mono_leq

#define mono_add     mono_add_avx
#define mono_sum     mono_sum_avx
#define mono_leq     mono_leq_avx
*/

#endif
#endif
