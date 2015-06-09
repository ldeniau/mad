#include <stdio.h>
#include <assert.h>
#include "mad_tpsa.h"

#define T struct tpsa
#define num_t double

// #define TRACE

void
mad_track_drift(T * restrict m[], num_t L, num_t B, num_t E)
{
#ifdef TRACE
  printf("track_drift\n");
#endif

  assert(m);

  T *x = m[0], *px = m[1];
  T *y = m[2], *py = m[3];
  T *s = m[4], *ps = m[5];

  T *t1 = mad_tpsa_new(x, mad_tpsa_default);
  T *t2 = mad_tpsa_new(s, mad_tpsa_same   );

  assert(x ); assert(y ); assert(s ); 
  assert(px); assert(py); assert(ps);
  assert(t1); assert(t2);

// l_pz = L/sqrt(1 + (2/B)*m.ps + m.ps^2 - m.px^2 - m.py^2)
  mad_tpsa_ax2pby2pcz2(1,ps,-1,px,-1,py,t1);   // ps^2 - px^2 - py^2
  mad_tpsa_axpbypc(2/B,ps, 1,t1, 1, t1);       // 1 + 2/B*m.ps + ps^2 - px^2 - py^2
  mad_tpsa_invsqrt(t1,L,t1);                   // L/sqrt(1 + 2/B*m.ps + ps^2 - px^2 - py^2) = pz_

  T *l_pz = t1;

// m.x = m.x + m.px*l_pz
// m.y = m.y + m.py*l_pz
  mad_tpsa_axypbzpc(1,px,l_pz, 1,x, 0, x);     // x + px*l_pz -> x
  mad_tpsa_axypbzpc(1,py,l_pz, 1,y, 0, y);     // y + py*l_pz -> y

// m.s = m.s + (1/B + m.ps)*l_pz - E/B
  mad_tpsa_copy(ps,t2);                        // ps
  mad_tpsa_set0(t2,1,1/B);                     // ps + 1/B
  mad_tpsa_axypbzpc(1,t2,l_pz, 1,s, -E/B, s);  // s + (ps + 1/B)*l_pz -> s

  mad_tpsa_del(t1);
  mad_tpsa_del(t2);
}

void
mad_track_kick(T * restrict m[], num_t L, num_t B, int n, num_t Bn[n], num_t An[n])
{
#ifdef TRACE
  printf("track_drift\n");
#endif

  assert(m);

  T *x = m[0], *px = m[1];
  T *y = m[2], *py = m[3];
  T *s = m[4], *ps = m[5];

  T *t1 = mad_tpsa_new(x, mad_tpsa_default);
  T *t2 = mad_tpsa_new(s, mad_tpsa_same   );

  assert(x ); assert(y ); assert(s ); 
  assert(px); assert(py); assert(ps);
  assert(t1); assert(t2);

#if 0
    local dir = 1 -- (m.dir or 1) * (m.charge or 1)
    local bbytwt

    m.bbxtw = const(m.bbxtw or same(m.px), e.bn[e.nmul] or 0)
    m.bbytw = const(m.bbytw or same(m.py), e.an[e.nmul] or 0)

    for j=e.nmul-1,1,-1 do
        bbytwt = m.x * m.bbytw - m.y * m.bbxtw + e.bn[j]
      m.bbxtw  = m.y * m.bbytw + m.x * m.bbxtw + e.an[j]
      m.bbytw  = bbytwt
    end

    m.px = m.px - e.L * dir * m.bbytw -- e.L was e.yl
    m.py = m.py + e.L * dir * m.bbxtw -- e.L was e.yl
    m.ps = sqrt(1 + (2/e.b)*m.ps  + m.ps^2) - 1 -- exact or not exact?
#endif

// TODO!!!

#if 0
// l_pz = L/sqrt(1 + (2/B)*m.ps + m.ps^2 - m.px^2 - m.py^2)
  mad_tpsa_ax2pby2pcz2(1,ps,-1,px,-1,py,t1);   // ps^2 - px^2 - py^2
  mad_tpsa_axpbypc(2/B,ps, 1,t1, 1, t1);       // 1 + 2/B*m.ps + ps^2 - px^2 - py^2
  mad_tpsa_invsqrt(t1,L,t1);                   // L/sqrt(1 + 2/B*m.ps + ps^2 - px^2 - py^2) = pz_

  T *l_pz = t1;

// m.x = m.x + m.px*l_pz
// m.y = m.y + m.py*l_pz
  mad_tpsa_axypbzpc(1,px,l_pz, 1,x, 0, x);     // x + px*l_pz -> x
  mad_tpsa_axypbzpc(1,py,l_pz, 1,y, 0, y);     // y + py*l_pz -> y

// m.s = m.s + (1/B + m.ps)*l_pz - E/B
  mad_tpsa_copy(ps,t2);                        // ps
  mad_tpsa_set0(t2,1,1/B);                     // ps + 1/B
  mad_tpsa_axypbzpc(1,t2,l_pz, 1,s, -E/B, s);  // s + (ps + 1/B)*l_pz -> s
#endif
  
  mad_tpsa_del(t1);
  mad_tpsa_del(t2);
}

#undef T
