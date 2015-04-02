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

  int CLK_TKS = sysconf(_SC_CLK_TCK);
  struct tms s0_tms, s1_tms;
  clock_t t0_clk, t1_clk, t0_cu, t1_cu, t0_tms, t1_tms;
  double t0_omp = 0, t1_omp = 0;

  #ifdef _OPENMP
  t0_omp = omp_get_wtime();
  #endif
  t0_clk = clock();
  t0_tms = times(&s0_tms);

  for (int l = 0; l < NL; ++l) {
    mad_tpsa_mul(a,b,c);
  }

  t1_tms = times(&s1_tms);
  t1_clk = clock();
  #ifdef _OPENMP
  t1_omp = omp_get_wtime();
  #endif

  t0_cu = s0_tms.tms_cutime;
  t1_cu = s1_tms.tms_cutime;

  fprintf(stderr, "t_omp: %.3f\t",          t1_omp - t0_omp);
  fprintf(stderr, "t_tms: %.3f\t", ((double)t1_tms - t0_tms)  / CLK_TKS);
  fprintf(stderr, "t_cu : %.3f\t", ((double)t1_cu  - t0_cu )  / CLK_TKS);
  fprintf(stderr, "t_clk: %.3f\t", ((double)t1_clk - t0_clk)  / CLOCKS_PER_SEC);
  fprintf(stderr, "\n");

  // mad_tpsa_print(a,NULL);
  // mad_tpsa_print(b,NULL);
  mad_tpsa_print(c,NULL);

  fclose(fin);
  return 0;
}
