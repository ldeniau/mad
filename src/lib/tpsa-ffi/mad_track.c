#include <stdio.h>
#include <assert.h>
#include "mad_tpsa.h"

#define T struct tpsa
#define num_t double

// #define TRACE

void
mad_track_drift(T * restrict m[], num_t L, num_t B_, num_t E)
{
#ifdef TRACE
  printf("track_drift\n");
#endif

  T *x = m[0], *px = m[1];
  T *y = m[2], *py = m[3];
  T *s = m[4], *ps = m[5];

  T *t1, *t2;

  // t1 = mad_tpsa_newd(mad_tpsa_desc(x), mad_tpsa_ordv(x,y,s));
  // t1 = mad_tpsa_new(x, mad_tpsa_ordv(x,y,s));
  t2 = mad_tpsa_new(s, mad_tpsa_same);
  t1 = mad_tpsa_new(x, mad_tpsa_default);

  // t2 = mad_tpsa_copy(x, mad_tpsa_new(x, mad_tpsa_same));    // exact   clone
  // t2 = mad_tpsa_copy(x, mad_tpsa_new(x, mad_tpsa_default)); // generic clone

//  l_pz = e.L/sqrt(1 + (2*B_)*m.ps + m.ps^2 - m.px^2 - m.py^2)
//  m.x = m.x + m.px*l_pz
//  m.y = m.y + m.py*l_pz
//  m.s = m.s + (B_ + m.ps)*l_pz - E*B_

  assert(x); assert(px);
  assert(y); assert(py);
  assert(s); assert(ps);
  assert(t1); assert(t2);

//  mad_tpsa_gtrunc(x,y,s,NULL);
//  mad_tpsa_gtrunc(3,x,y,s);

  mad_tpsa_ax2pby2pcz2(1,ps,-1,px,-1,py,t1);   // ps^2 - px^2 - py^2
  mad_tpsa_axpbypc(2*B_,ps, 1,t1, 1, t1);      // 1 + 2/e.b*m.ps + ps^2 - px^2 - py^2
  mad_tpsa_invsqrt(t1,L,t1);                   // L/sqrt(1 + 2/e.b*m.ps + ps^2 - px^2 - py^2) = pz_

  T *pz_ = t1;

  mad_tpsa_axypbzpc(1,px,pz_, 1,x, 0, x);      // x + px*pz_ -> x
  mad_tpsa_axypbzpc(1,py,pz_, 1,y, 0, y);      // y + py*pz_ -> y

  mad_tpsa_copy(ps,t2);                        // ps
  mad_tpsa_set0(t2,1.0,B_);                    // 1/e.b + ps
  mad_tpsa_axypbzpc(1,t2,pz_, 1,s, E, s);      // s + (B_ + ps)*pz_ -> s

  mad_tpsa_del(t1);
  mad_tpsa_del(t2);
}

#undef T