a_scratch_size.o:           a_scratch_size.f90
	gfortran -c -O3 $< -o $@
b_da_arrays_all.o:          b_da_arrays_all.f90         a_scratch_size.o
	gfortran -c -O3 $< -o $@
c_dabnew_berz.o:            c_dabnew_berz.f90           b_da_arrays_all.o
	gfortran -c -O3 $< -o $@
c_tpsa_interface.o:         c_tpsa_interface.F90        c_dabnew_berz.o
	gfortran -c -O3 -fPIC $< -o $@

yangtpsa.o:                 tpsa.h tpsa.cpp
	g++ -c -O3 tpsa.cpp -fPIC -o yangtpsa.o

c_tpsa_interface.so:        c_tpsa_interface.o           yangtpsa.o
	gfortran -O3 -shared -fPIC c_tpsa_interface.o yangtpsa.o -o libc_tpsa_interface.so

clean:
	rm *.o


