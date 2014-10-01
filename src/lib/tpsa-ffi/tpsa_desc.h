#ifndef TPSA_DESC_H
#define TPSA_DESC_H

#ifndef __DESC_DECL_
#define __DESC_DECL_
typedef struct desc desc_t;
#endif

typedef int           idx_t;
typedef unsigned char mono_t;
typedef struct table  table_t;

desc_t* tpsa_desc_new      (int nv, mono_t var_ords[nv], int mvo);
desc_t* tpsa_desc_knobs_new(int nv, mono_t var_ords[nv], int mvo,
	                        int nk, mono_t knb_ords[nk], int mko);

static inline void mono_clr(int n, mono_t m[n]);
static inline void mono_cpy(const int n, const mono_t src[n], mono_t dst[n]);
static inline int  mono_equ(const int n, const mono_t a[n], const mono_t b[n]);
static inline void mono_add(const int n, const mono_t a[n], const mono_t b[n], mono_t c[n]);
static inline mono_t mono_sum(int n, const mono_t m[n]);
static inline void mono_acc(int n, const mono_t a[n], mono_t r[n]);
static inline int  mono_elem_leq(int n, const mono_t a[n], const mono_t b[n]);
static inline int  mono_isvalid(int n, const mono_t m[n], const mono_t a[n], const mono_t o);
static inline int  mono_nxt_by_var(int n, mono_t m[n], const mono_t a[n], const mono_t o);
static inline void mono_nxt_by_unk(int n, const mono_t a[n], int i, int j, mono_t m[n]);
static inline void mono_print(int n, const mono_t m[n]);

static inline void tbl_by_var(desc_t *d);
static inline void tbl_by_ord(desc_t *d);
static inline int  tbl_index_H(const desc_t *d, const mono_t a[]);
static inline void tbl_print_H(const desc_t *d);

#endif