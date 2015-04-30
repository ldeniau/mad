local ffi = require"ffi"

ffi.cdef[[
  double omp_get_wtime();
]]

return ffi.load("/usr/lib/gcc/x86_64-linux-gnu/4.9/libgomp.so")

