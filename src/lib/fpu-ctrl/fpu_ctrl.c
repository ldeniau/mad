/*
 Small interface to SSE function for setting up the FPU flags
*/
#include <immintrin.h>

// unsigned int _mm_getcsr();
// void         _mm_setcsr(unsigned int csr_value);


unsigned int
getcsr()
{
  return _mm_getcsr();
}

void
setcsr(unsigned int csr_value)
{
  _mm_setcsr(csr_value);
}

