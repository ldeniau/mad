SRC = $(wildcard *.f90)

libmadx-track: $(SRC)
	gfortran -O3 -shared -fPIC $^ -o $@.so

twiss.f90: utils.f90
track.f90: twiss.f90 utils.f90

clean:
	rm -rf *.mod