#ifndef MAD_TPSA_H
#define MAD_TPSA_H

#include "mad.h"
#include "mad_mono.h"

// --- types -------------------------------------------------------------------

struct tpsa;
struct tpsa_desc;

// --- interface ---------------------------------------------------------------

#define T struct tpsa

T*    mad_tpsa_newd    (struct tpsa_desc *d);  // to use const?

T*    mad_tpsa_new     (const T *t);
T*    mad_tpsa_clone   (const T *t); // new + copy
void  mad_tpsa_copy    (const T *src, T *dst);
void  mad_tpsa_clean   (      T *t);
void  mad_tpsa_del     (      T *t);

void  mad_tpsa_seti    (      T *t, int i, num_t v);
void  mad_tpsa_setm    (      T *t, int n, const ord_t m[n], num_t v);

num_t mad_tpsa_geti    (const T *t, int i);
num_t mad_tpsa_getm    (const T *t, int n, const ord_t m[n]);

int   mad_tpsa_idx     (const T *t, int n, const ord_t m[n]);

void  mad_tpsa_add     (const T *a, const T *b, T *c);
void  mad_tpsa_sub     (const T *a, const T *b, T *c);
void  mad_tpsa_mul     (const T *a, const T *b, T *c);

void  mad_tpsa_print   (const T *t);

#undef T

// -----------------------------------------------------------------------------
#endif
