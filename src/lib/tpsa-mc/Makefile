libtpsa-mc.so: tpsa.cpp tpsa.h
	g++ -std=c++0x -Wall -W -pedantic -O3 -shared -fPIC -fopenmp tpsa.cpp -o libtpsa-mc.so

clean:
	rm -f *.o *.so
