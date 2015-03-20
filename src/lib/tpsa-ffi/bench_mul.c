/*
 Reads two TPSAs from file, multiplies them num_loops times and
 prints the result to stdout
*/

#include <stdio.h>
#include <time.h>
#include "mad_tpsa_desc.h"
#include "mad_tpsa.h"

#define D struct tpsa_desc
#define T struct tpsa

int main(int argc, char *argv[])
{
  fprintf(stderr, "Usage: ./bench_mul input_file.txt num_loops\n");
  assert(argc == 3);
  FILE *fin = fopen(argv[1], "r");

  D *da = mad_tpsa_desc_read(fin);
  T *a  = mad_tpsa_newd(da, NULL);
  mad_tpsa_read_coef(a,fin);

  D *db = mad_tpsa_desc_read(fin);
  assert(da == db);
  T *b = mad_tpsa_newd(db, NULL);
  mad_tpsa_read_coef(b,fin);

  T *c = mad_tpsa_new(b);

  int NL = atoi(argv[2]);
  clock_t start = clock();
  for (int l = 0; l < NL; ++l)
    mad_tpsa_mul(a,b,c);
  clock_t end = clock();
  fprintf(stderr, "Done!\n Loops: %d Time: %.2f s\n", NL, ((double)end-start)/CLOCKS_PER_SEC);

  mad_tpsa_print(c,NULL);

  fclose(fin);
  return 0;
}
