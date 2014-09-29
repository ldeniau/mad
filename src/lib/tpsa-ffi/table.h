#ifndef TABLE_H
#define TABLE_H

#include "defs.h"

struct table {
  int     *o, *i, *ps;
  mono_t **m;
};


int  tbl_by_var(table_t *t, int nv, int no, int nc, const mono_t a[nv], mono_t mons[nc]);
int  tbl_by_ord(table_t *to, table_t *tv, int no, int nc);
void tbl_print(table_t *t, int nv, int no, int nc);
void tbl_build_H(desc_t *d, int nv);

#endif
