/*
 Reads two TPSAs from file, multiplies them num_loops times and
 prints the result to stdout
*/

#define _GNU_SOURCE
#include <stdio.h>
#include <time.h>
#include <sys/times.h>
#include <unistd.h>
#include <omp.h>
#include "mad_tpsa_desc.h"
#include "mad_tpsa.h"

#define D struct tpsa_desc
#define T struct tpsa

double get_time()
{
  return (double) clock () / (double) CLOCKS_PER_SEC;
}

int main(int argc, char *argv[])
{
  fprintf(stderr, "Usage: ./bench_mul nv no num_loops\n");
  if (argc < 4) {
    fprintf(stderr, "Not enough args\n");
    return 1;
  }
  int   nv = atoi(argv[1]);
  ord_t no = atoi(argv[2]);
  int   NL = atoi(argv[3]);

  ord_t ords[nv];
  for (int i = 0; i < nv; ++i)
    ords[i] = no;
  D *d = mad_tpsa_desc_new(nv,ords,no);
  T *a = mad_tpsa_newd(d, NULL);
  T *b = mad_tpsa_newd(d, NULL);
  T *c = mad_tpsa_newd(d, NULL);

  double val = 1.1, inc = 0.1;
  for (int i = 0; i < mad_tpsa_desc_nc(d,&no); ++i) {
    mad_tpsa_seti(a,i,val);
    mad_tpsa_seti(b,i,val);
    val += inc;
  }

  double t0, t1;
  #ifdef _OPENMP
  t0 = omp_get_wtime();
  #else
  t0 = get_time();
  #endif
  for (int l = 0; l < NL; ++l) {
    mad_tpsa_mul(a,b,c);
  }
  #ifdef _OPENMP
  t1 = omp_get_wtime();
  #else
  t1 = get_time();
  #endif
  printf("%d\t%d\t%d\t%.3f\n", nv, no, NL, t1-t0);

  // mad_tpsa_print(a,NULL);
  // mad_tpsa_print(b,NULL);
  // mad_tpsa_print(c,NULL);

  return 0;
}
