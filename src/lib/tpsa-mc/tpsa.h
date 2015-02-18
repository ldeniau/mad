#ifndef TPSA_H
#define TPSA_H

// C interface for MapClass TPSA

#ifndef TPSA_IMPLEMENTATION
typedef struct tpsa_t tpsa_t;
#endif

#ifdef __cplusplus
extern "C" {
#endif
    void init();  // not actually used, just providing the same interface
    tpsa_t* tpsa_create(int nv, int mo);
    void tpsa_destroy(tpsa_t*);
    void tpsa_copy(tpsa_t* src, tpsa_t* dest);
    
    void tpsa_setConst(tpsa_t*, double val);
    void tpsa_setCoeff(tpsa_t*, const unsigned char* mon,
                       const int monLen, const double val);
    double tpsa_getCoeff(const tpsa_t*, const unsigned char* mon,
                         const int monLen);

    void tpsa_add(tpsa_t* op1, tpsa_t* op2, tpsa_t* res);
    void tpsa_mul(tpsa_t* op1, tpsa_t* op2, tpsa_t* res);
    void tpsa_concat(tpsa_t* ma, int aLen, tpsa_t* mb, int bLen,
                     tpsa_t* mc, int cLen);

    void tpsa_print(tpsa_t*);

#ifdef __cplusplus
}
#endif

#endif // TPSA_H
