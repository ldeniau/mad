CC=gcc
override CFLAGS += -std=c11 -W -Wall -Wextra -pedantic -Os -ffast-math
override CLIBS  += -lm -lgsl -lgslcblas

.PHONY: tpsaFFI

tpsaFFI: libtpsa-ffi-$(CC).so

all: tpsaFFI bench_mul

SRC = mad_tpsa.c mad_track.c mad_sse_avx.c

libtpsa-ffi-$(CC).so: $(SRC) tpsa_*.tc mad_*.h
ifeq ($(CC),gcc)
ifdef OPENMP
	$(CC) $(CFLAGS) -shared -fopenmp -static-libgcc -fPIC $(SRC) -o libtpsa-ffi-$(CC).so $(CLIBS)
else
	$(CC) $(CFLAGS) -shared          -static-libgcc -fPIC $(SRC) -o libtpsa-ffi-$(CC).so $(CLIBS)
endif
endif
ifeq ($(CC),icc)
ifdef OPENMP
	$(CC) $(CFLAGS) -dynamiclib -openmp -static-intel -fPIC $(SRC) -o libtpsa-ffi-$(CC).so
else
	$(CC) $(CFLAGS) -dynamiclib         -static-intel -fPIC $(SRC) -o libtpsa-ffi-$(CC).so
endif
endif
	ln -sf libtpsa-ffi-$(CC).so libtpsa-ffi.so

ifdef OPENMP
bench_mul:	override CFLAGS += -fopenmp
endif
ifdef PROFILING
bench_mul:	override CFLAGS += -fno-omit-frame-pointer -g
track:	override CFLAGS += -pg
endif

bench_mul:	bench_mul.c mad_*.c tpsa_*.tc mad_*.h
	$(CC) $(CFLAGS) bench_mul.c mad_*.c -o bench_mul $(CLIBS)

track:  mad_*.c tpsa_*.tc mad_*.h
	$(CC) $(CFLAGS) mad_*.c -o track $(CLIBS)

clean:
	rm -f libtpsa-ffi*.so bench_mul track
