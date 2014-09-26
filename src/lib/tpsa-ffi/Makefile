CC=gcc

.PHONY: tpsaFFI

tpsaFFI: libtpsa-ffi-$(CC).so

libtpsa-ffi-$(CC).so: tpsa.c
ifeq ($(CC),gcc)
ifdef OPENMP
	$(CC) -std=c99 -Wall -W -pedantic -O3 -shared -fopenmp -static-libgcc -fPIC *.c -o libtpsa-ffi-$(CC).so
else
	$(CC) -std=c99 -Wall -W -pedantic -O3 -shared          -static-libgcc -fPIC *.c -o libtpsa-ffi-$(CC).so
endif
endif
ifeq ($(CC),icc)
ifdef OPENMP
	$(CC) -std=c99 -Wall -W -pedantic -O3 -dynamiclib -openmp -static-intel -fPIC *.c -o libtpsa-ffi-$(CC).so
else
	$(CC) -std=c99 -Wall -W -pedantic -O3 -dynamiclib         -static-intel -fPIC *.c -o libtpsa-ffi-$(CC).so
endif
endif
	ln -sf libtpsa-ffi-$(CC).so libtpsa-ffi.so

clean:
	rm -f libtpsa-ffi*.so