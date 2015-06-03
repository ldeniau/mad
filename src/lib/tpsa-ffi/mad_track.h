#ifndef MAD_TRACK_H
#define MAD_TRACK_H

// --- types -------------------------------------------------------------------

struct tpsa;

// --- interface ---------------------------------------------------------------

#define T     struct tpsa
#define num_t double

void mad_track_drift(T * restrict m[], num_t L, num_t B_, num_t E);

#undef T

// -----------------------------------------------------------------------------
#endif
