#include <iostream>
#include <limits>
#include <string>
#include "Pol.h"

typedef Polynom<double> tpsa_t;

#define TPSA_IMPLEMENTATION
#include "tpsa.h"


const double eps = std::numeric_limits<double>::epsilon();
const vector<string> vars = {"x1", "x2", "x3", "x4", "x5", "x6",
                             "x7", "x8", "x9", "x10", "x11", "x12"};

// not actually used, just providing the same interface
void init() {}

/** Allocates a new tpsa with given number of vars and maximum order */
tpsa_t* tpsa_create(int nv, int mo) {
    vector<string> v(vars.begin(), vars.begin() + nv);
    tpsa_t* p = new tpsa_t(mo, eps, v, 0.0);    // initialize with 0
    return p;
}


/** Frees the memory used by the tpsa */
void tpsa_destroy(tpsa_t* p) {
    delete p;
}


/** Makes the contents of `dest` identical to `src` */
void tpsa_copy(tpsa_t* src, tpsa_t* dest) {
    *dest = *src;    // does this destroy src ? (Pol.h)
}


/** Sets the constant term of the given tpsa */
void tpsa_setConst(tpsa_t* p, double val) {
    vector<int> cst(p->vars.size(), 0);    // {0 0 ... 0} is the constant term
    p->terms[cst] = val;
}


/** Sets the coefficient of the specified monomial in the tpsa
 *
 *  Monomial should be an array of bytes with the exponents of each var  \
 *  e.g {1, 0, 2, 2} means x * z^2 * t^2           */
void tpsa_set(tpsa_t* p, const unsigned char* mon, const int monLen,
                   const double val) {
    vector<int> t(p->vars.size());    // make it the right size
    copy(mon, mon + monLen, t.begin());
    p->terms[t] = val;
}


/** Returns the coefficient of the specified monomial from the tpsa
 *  See set for definition of mon */
double tpsa_get(const tpsa_t* p, const unsigned char* mon, const int monLen) {
    vector<int> t(p->vars.size());    // make it the right size
    copy(mon, mon + monLen, t.begin());
    auto val = p->terms.find(t);
    return val != p->terms.end() ? val->second : 0.0;
}


/** res = op1 + op2 */
void tpsa_add(tpsa_t* op1, tpsa_t* op2, tpsa_t* res) {
    *res = *op1 + *op2;
}


/** res = op1 * op2 */
void tpsa_mul(tpsa_t* op1, tpsa_t* op2, tpsa_t* res) {
    tpsa_t *a = op1, *b = op2;
    if (a == res) {
        a = tpsa_create(a->vars.size(), a->order);
        tpsa_copy(op1, a);
    }
    if (b == res) {
        b = tpsa_create(b->vars.size(), b->order);
        tpsa_copy(op2, b);
    }
    *res = *a * *b;
}


/** Given 3 arrays of TPSAs (ma, mb, mc), performs mc = ma o mb
 *  ma, mb and mc must have compatible lengths */
void tpsa_concat(tpsa_t** ma, int aLen, tpsa_t** mb, int bLen,
                 tpsa_t** mc, int cLen) {
    // not implemented yet
}


/** Prints the tpsa to stdout */
void tpsa_print(tpsa_t* p) {
    p->printpol();
}



