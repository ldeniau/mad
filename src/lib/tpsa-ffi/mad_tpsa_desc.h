#ifndef MAD_TPSA_DESC_H
#define MAD_TPSA_DESC_H

#include "mad_mono.h"

// --- interface ---------------------------------------------------------------

#define D struct tpsa_desc

D*    mad_tpsa_desc_new  (int nv, const ord_t var_ords[nv], ord_t mo);
D*    mad_tpsa_desc_newk (int nv, const ord_t var_ords[nv], ord_t mvo, // with knobs
                          int nk, const ord_t knb_ords[nk], ord_t mko);
void  mad_tpsa_desc_del  (      D *d);

int   mad_tpsa_desc_nc   (const D *d);

#undef D

// -----------------------------------------------------------------------------
#endif
