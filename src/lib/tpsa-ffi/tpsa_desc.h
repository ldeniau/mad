#ifndef TPSA_DESC_H
#define TPSA_DESC_H

#define _TPSA_DESC_NUM_ 1000    // number of descriptors to store

typedef int           idx_t;
typedef unsigned char mono_t;
typedef struct desc desc_t;

desc_t* tpsa_desc_get(int nv, mono_t var_ords[nv], mono_t mo);
void    tpsa_desc_del(desc_t *d);
#endif