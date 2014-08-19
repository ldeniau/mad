## simple make file to build the BERZ Fortran lib so it can be interfaced from
## luajit's FFI: make sharedBerz

GF = /usr/bin/gfortran    # fortran compiler

GFFLAGS = -O3

sharedBerz: TPSALib.f TPSALib_prm.f
	echo "TODO: try to make from c_dabnew_berz.f90"
	$(GF) $(GFFLAGS) -shared TPSALib.f -o TPSALib-Berz.so -fPIC
