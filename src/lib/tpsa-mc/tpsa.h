#ifndef TPSA_H
#define TPSA_H

// C interface for MapClass TPSA

#ifndef TPSA_IMPLEMENTATION
typedef struct tpsa_t tpsa_t;
typedef struct map_t  map_t;
#endif

#ifdef __cplusplus
extern "C" {
#endif
  // -- TPSA -----------------------------------------------------------------
  tpsa_t* tpsa_init    (int nv, int mo);
  tpsa_t* tpsa_copy    (const tpsa_t *src, tpsa_t *dest_);
  tpsa_t* tpsa_same    (const tpsa_t *t);
  void    tpsa_destroy (      tpsa_t *t);

  double  tpsa_get     (const tpsa_t *t, int monLen, const unsigned char *mon);
  void    tpsa_set     (      tpsa_t *t, int monLen, const unsigned char *mon, double val);

  void    tpsa_add     (tpsa_t *a, tpsa_t *b, tpsa_t *c);
  void    tpsa_sub     (tpsa_t *a, tpsa_t *b, tpsa_t *c);
  void    tpsa_mul     (tpsa_t *a, tpsa_t *b, tpsa_t *c);
  void    tpsa_div     (tpsa_t *a, tpsa_t *b, tpsa_t *c);

  void    tpsa_print   (tpsa_t *t);

  // -- MAPS -----------------------------------------------------------------
  map_t*  tpsa_map_create (int nv, tpsa_t *ma[]);
  void    tpsa_map_destroy(map_t *m);
  void    tpsa_map_print  (map_t *m);
  void    tpsa_map_compose(map_t *ma, map_t *mb, map_t *mc);

#ifdef __cplusplus
}
#endif

#endif // TPSA_H
