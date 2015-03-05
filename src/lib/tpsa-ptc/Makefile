libdabnew.so: a_scratch_size.o b_da_arrays_all.o c_dabnew.o
	gfortran -fcheck=all -shared -fPIC *.o -o $@

a_scratch_size.o:           a_scratch_size.f90
	gfortran -c -O3 -fPIC $< -o $@

b_da_arrays_all.o:          b_da_arrays_all.f90         a_scratch_size.o
	gfortran -c -O3  -fPIC $< -o $@

c_dabnew.o:                 c_dabnew.f90                b_da_arrays_all.o
	gfortran -c -O3  -fPIC $< -o $@

clean:
	rm -f *.o *.so *.mod


