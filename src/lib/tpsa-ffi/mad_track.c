#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "mad_tpsa.h"

#include "track_drift.tc"

int
main(void)
{
	typedef unsigned char ord_t;

	typedef struct tpsa tpsa_t;
	typedef struct tpsa_desc desc_t;
	typedef struct { tpsa_t *x,*px,*y,*py,*s,*ps; } map_t;

	desc_t *d = mad_tpsa_dnew(6, (ord_t[]){2,2,2,2,2,2}, 0, 0);
	map_t m = {
		.x  = mad_tpsa_new(d, 0),
		.px = mad_tpsa_new(d, 0),
		.y  = mad_tpsa_new(d, 0),
		.py = mad_tpsa_new(d, 0),
		.s  = mad_tpsa_new(d, 0),
		.ps = mad_tpsa_new(d, 0),
	};

	mad_tpsa_set0(m.x,  0,0);
	mad_tpsa_set0(m.y,  0,0);
	mad_tpsa_set0(m.s,  0,0);
	mad_tpsa_set0(m.px, 0,0.001);
	mad_tpsa_set0(m.py, 0,0.001);
	mad_tpsa_set0(m.ps, 0,1e-6);
	mad_tpsa_setm(m.ps, 3,(ord_t[]){1,0,0}, 0.0,1.0);
	mad_tpsa_setm(m.ps, 3,(ord_t[]){0,0,1}, 0.0,1.0);

	for (int i=0; i < 3000000; i++) {
    // printf("%d-----------------\n", i);
	 	mad_tpsa_drift((tpsa_t**)&m, 1, 1, 0);
  }

  mad_tpsa_print(m.x, stdout);
  mad_tpsa_print(m.y, stdout);
  mad_tpsa_print(m.s, stdout);
  mad_tpsa_print(m.px, stdout);
  mad_tpsa_print(m.py, stdout);
  mad_tpsa_print(m.ps, stdout);

  mad_tpsa_del(m.x );
  mad_tpsa_del(m.y );
  mad_tpsa_del(m.s );
  mad_tpsa_del(m.px);
  mad_tpsa_del(m.py);
  mad_tpsa_del(m.ps);
  mad_tpsa_ddel(d);

	return 0;
}
