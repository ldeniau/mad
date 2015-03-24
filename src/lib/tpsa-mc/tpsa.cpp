#include <iostream>
#include <limits>
#include <string>
#include "Pol.h"
#include "Polmap.h"

typedef Polynom<double> tpsa_t;
typedef Polmap<double> map_t;

#define TPSA_IMPLEMENTATION
#include "tpsa.h"


const double eps = std::numeric_limits<double>::epsilon();
const vector<string> vars = {"x", "px", "y", "py", "s", "d",
                             "x7", "x8", "x9", "x10", "x11", "x12"};

/* Allocates a new tpsa with given number of vars and maximum order */
tpsa_t* tpsa_init(int nv, int mo) {
  assert((unsigned int)nv <= vars.size());
  vector<string> vars_in_use(vars.begin(),vars.begin()+nv);
  return new tpsa_t(mo,eps,vars_in_use,0.0);    // initialized with 0s
}

/* Frees the memory used by the tpsa */
void tpsa_destroy(tpsa_t *t) {
  delete t;
}

tpsa_t* tpsa_same(const tpsa_t *t) {
    return new tpsa_t(t->order,t->eps,t->vars,0.0);
}

/* Makes a copy of `src`, puts it into `dest_` and returns it
 * If dest is missing, allocates a new one and returns it
 */
tpsa_t* tpsa_copy(const tpsa_t *src, tpsa_t *dest_) {
  if (!dest_)
    dest_ = tpsa_same(src);
  *dest_ = *src;
  return dest_;
}

/* Sets the coefficient of the specified monomial in the tpsa
 *
 *  Monomial should be an array of bytes with the exponents of each var
 *  e.g {1, 0, 2, 2} means x * z^2 * t^2           */
void tpsa_set(tpsa_t *t, int monLen, const unsigned char *mon, double val) {
  vector<int> vmon(t->vars.size());
  copy(mon, mon+monLen, vmon.begin());
  t->terms[vmon] = val;
}

/* Returns the coefficient of the specified monomial from the tpsa
 *  See set for definition of mon
 */
double tpsa_get(const tpsa_t *t, int monLen, const unsigned char *mon) {
  vector<int> vmon(t->vars.size());
  copy(mon, mon+monLen, vmon.begin());
  auto val = t->terms.find(vmon);
  return val != t->terms.end() ? val->second : 0.0;
}

void tpsa_add(tpsa_t *a, tpsa_t *b, tpsa_t *c) {
  *c = *a + *b;
}

void tpsa_sub(tpsa_t *a, tpsa_t *b, tpsa_t *c) {
  *c = *a - *b;
}

void tpsa_mul(tpsa_t *a, tpsa_t *b, tpsa_t *c) {
  *c = *a * *b;
}

void tpsa_div(tpsa_t *a, tpsa_t *b, tpsa_t *c) {
  *c = *a / *b;
}

void tpsa_print(tpsa_t *t) {
  t->printpol();
}

map_t* tpsa_map_create(int nv, tpsa_t *ma[])
{
  assert((unsigned int)nv <= vars.size());
  vector<string> vars_in_use(vars.begin(), vars.begin()+nv);
  map_t *m = new map_t();
  for (int i = 0; i < nv; ++i)
    m->pols[vars[i]] = *ma[i];
  return m;
}

void tpsa_map_destroy(map_t *m)
{
  delete m;
}

void tpsa_map_compose(map_t *ma, map_t *mb, map_t *mc)
{
  *mc = ma->parallel_composition(*mb);
}

void tpsa_map_print(map_t *m)
{
  m->printpolmap();
}


