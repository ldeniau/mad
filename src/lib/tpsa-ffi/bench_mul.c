/*
 Reads two TPSAs from file, multiplies them num_loops times and
 prints the result to stdout
*/

#include <stdio.h>
#include <time.h>
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
  fprintf(stderr, "Usage: ./bench_mul input_file.txt num_loops\n");
  if (argc != 3) {
    fprintf(stderr, "Not enough args\n");
    return 1;
  }

  FILE *fin = fopen(argv[1], "r");

  D *da = mad_tpsa_desc_scan(fin);
  T *a  = mad_tpsa_newd(da, NULL);
  mad_tpsa_scan_coef(a,fin);

  D *db = mad_tpsa_desc_scan(fin);
  assert(da == db);
  T *b = mad_tpsa_newd(db, NULL);
  mad_tpsa_scan_coef(b,fin);

  T *c = mad_tpsa_new(b);

  int NL = atoi(argv[2]);

  #ifdef _OPENMP
    double start = omp_get_wtime();
  #else
    double start = get_time();
  #endif

  for (int l = 0; l < NL; ++l)
    mad_tpsa_mul(a,b,c);

  #ifdef _OPENMP
    double end = omp_get_wtime();
  #else
    double end = get_time();
  #endif


  printf("%.3f\n", end-start);

  // mad_tpsa_print(a,NULL);
  // mad_tpsa_print(b,NULL);
  // mad_tpsa_print(c,NULL);

  fclose(fin);
  return 0;
}
