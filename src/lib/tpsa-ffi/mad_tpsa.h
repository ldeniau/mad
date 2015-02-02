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

num_t mad_tpsa_abs     (const T *t);
num_t mad_tpsa_abs2    (const T *t);
void  mad_tpsa_rand    (      T *t, num_t low, num_t high, int seed);

void  mad_tpsa_der     (const T *a, int var,    T *c);
void  mad_tpsa_pos     (const T *a,             T *c);
num_t mad_tpsa_comp    (const T *a, const T *b);

void  mad_tpsa_inv     (const T *a, T *c);
void  mad_tpsa_sqrt    (const T *a, T *c);
void  mad_tpsa_isrt    (const T *a, T *c);
void  mad_tpsa_exp     (const T *a, T *c);
void  mad_tpsa_log     (const T *a, T *c);
void  mad_tpsa_sin     (const T *a, T *c);
void  mad_tpsa_cos     (const T *a, T *c);
void  mad_tpsa_sincos  (const T *a, T *c);
void  mad_tpsa_sinh    (const T *a, T *c);
void  mad_tpsa_cosh    (const T *a, T *c);
void  mad_tpsa_sirx    (const T *a, T *c);
void  mad_tpsa_corx    (const T *a, T *c);
void  mad_tpsa_sidx    (const T *a, T *c);

void  mad_tpsa_tan     (const T *a, T *c);
void  mad_tpsa_cot     (const T *a, T *c);
void  mad_tpsa_asin    (const T *a, T *c);
void  mad_tpsa_acos    (const T *a, T *c);
void  mad_tpsa_atan    (const T *a, T *c);
void  mad_tpsa_acot    (const T *a, T *c);
void  mad_tpsa_tanh    (const T *a, T *c);
void  mad_tpsa_coth    (const T *a, T *c);
void  mad_tpsa_asinh   (const T *a, T *c);
void  mad_tpsa_acosh   (const T *a, T *c);
void  mad_tpsa_atanh   (const T *a, T *c);
void  mad_tpsa_acoth   (const T *a, T *c);

void  mad_tpsa_erf     (const T *a, T *c);

void  mad_tpsa_add     (const T *a, const T *b, T *c);
void  mad_tpsa_sub     (const T *a, const T *b, T *c);
void  mad_tpsa_mul     (const T *a, const T *b, T *c);
void  mad_tpsa_pow     (const T *a,             T *c, int p);

void  mad_tpsa_scale   (num_t ca, const T *a,                          T *c);
void  mad_tpsa_axpb    (num_t ca, const T *a,              const T *b, T *c);
void  mad_tpsa_axpby   (num_t ca, const T *a,    num_t cb, const T *b, T *c);

void  mad_tpsa_compose (int   sa, const T *ma[], int sb,   const T *mb[], int sc, T *mc[]);
void  mad_tpsa_minv    (int   sa, const T *ma[], int sc,         T *mc[]);
void  mad_tpsa_pminv   (int   sa, const T *ma[], int sc,         T *mc[], int row_select[sa]);

void  mad_tpsa_print   (const T *t);

#undef T

// -----------------------------------------------------------------------------
#endif
