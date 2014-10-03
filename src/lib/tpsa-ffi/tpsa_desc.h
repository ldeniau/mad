#ifndef TPSA_DESC_H
#define TPSA_DESC_H

#define _TPSA_DESC_NUM_ 1000    // number of descriptors to store

typedef unsigned char mono_t;
typedef struct desc   desc_t;

desc_t* tpsa_get_desc      (int nv, mono_t var_ords[nv], mono_t mo);
desc_t* tpsa_get_desc_knobs(int nv, mono_t var_ords[nv], mono_t mvo,
                            int nk, mono_t knb_ords[nk], mono_t mko);
void    tpsa_del_desc(desc_t *d);
#endif
