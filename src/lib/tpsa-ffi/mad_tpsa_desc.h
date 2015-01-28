#ifndef MAD_TPSA_DESC_H
#define MAD_TPSA_DESC_H

#include "mad_mono.h"

// --- interface ---------------------------------------------------------------

#define D struct tpsa_desc

D*    mad_tpsa_desc_new  (ord_t mo, int nv, const ord_t var_ords[nv]);
D*    mad_tpsa_desc_newk (ord_t mo, int nv, const ord_t var_ords[nv], ord_t mvo, // with knobs
                                    int nk, const ord_t knb_ords[nk], ord_t mko);
void  mad_tpsa_desc_del  (      D *d);

int   mad_tpsa_desc_nc   (const D *d);
ord_t mad_tpsa_desc_trunc(      D *d, ord_t *to);
#undef D

// -----------------------------------------------------------------------------
#endif
