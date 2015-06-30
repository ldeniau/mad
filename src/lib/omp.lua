local ffi = require"ffi"

ffi.cdef[[
  double omp_get_wtime();
]]

return ffi.load("libgomp")  -- make sure libgomp is in LD_LIBRARY_PATH or package.cpath

