CC=gcc
override CFLAGS += -std=c99 -Wall -W -pedantic -O3
override CLIBS  += -lm -lgsl -lgslcblas

.PHONY: tpsaFFI

tpsaFFI: libtpsa-ffi-$(CC).so

libtpsa-ffi-$(CC).so: mad_*.c tpsa_*.tc mad_*.h
ifeq ($(CC),gcc)
ifdef OPENMP
	$(CC) $(CFLAGS) -shared -fopenmp -static-libgcc -fPIC mad_*.c -o libtpsa-ffi-$(CC).so $(CLIBS)
else
	$(CC) $(CFLAGS) -shared          -static-libgcc -fPIC mad_*.c -o libtpsa-ffi-$(CC).so $(CLIBS)
endif
endif
ifeq ($(CC),icc)
ifdef OPENMP
	$(CC) $(CFLAGS) -dynamiclib -openmp -static-intel -fPIC mad_*.c -o libtpsa-ffi-$(CC).so
else
	$(CC) $(CFLAGS) -dynamiclib         -static-intel -fPIC mad_*.c -o libtpsa-ffi-$(CC).so
endif
endif
	ln -sf libtpsa-ffi-$(CC).so libtpsa-ffi.so

bench_mul:	CFLAGS += -fno-omit-frame-pointer -pg
bench_mul:	bench_mul.c mad_*.c tpsa_*.tc mad_*.h
	$(CC) $(CFLAGS) bench_mul.c mad_*.c -o bench_mul $(CLIBS)

clean:
	rm -f libtpsa-ffi*.so bench_mul
