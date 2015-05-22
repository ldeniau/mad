#ifndef MAD_TPSA_DESC_H
#define MAD_TPSA_DESC_H

#include "mad_mono.h"

// --- interface ---------------------------------------------------------------

#define D struct tpsa_desc
#define str_t const char*

D*    mad_tpsa_desc_new    (int nv, const ord_t var_ords[nv], const ord_t map_ords_[nv], str_t var_nam_[nv]);
D*    mad_tpsa_desc_newk   (int nv, const ord_t var_ords[nv], const ord_t map_ords_[nv], str_t var_nam_[nv],
                            int nk, const ord_t knb_ords[nk], ord_t dk); // knobs
D*    mad_tpsa_desc_scan  (FILE *stream_);

void  mad_tpsa_desc_del   (      D *d);

int   mad_tpsa_desc_nc    (const D *d, ord_t ord); // if not 0 <    to <= d_mo then to = d_mo
ord_t mad_tpsa_desc_gtrunc(      D *d, ord_t to);  // if not 0 <= to <= d_mo then to = d_mo
ord_t mad_tpsa_desc_mo    (const D *d);
#undef D

// -----------------------------------------------------------------------------
#endif
