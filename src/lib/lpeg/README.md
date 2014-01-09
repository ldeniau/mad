###Installing:  
  Run the makefile contained in the lpeg-0.12-folder then move lpeg.so to src/libs/lpeg.  
  
###Using re:  
  To use re, one needs to use the wrapper in src/mad/lang.  
  ``` lua
    local re = require"mad.lang.re"
  ```
  This acts just as lpeg.re does, so with the exeption of the wrapper, one can use it just as the documentation says.  
  
###Using lpeg:  
  To use lpeg, one must do what the wrapper for lpeg does, putting lpeg on the cpath of Lua and removing it from the path afterwards.  
  ``` lua
    local pcp = package.cpath
    package.cpath = ";;./libs/lpeg/?.so;"..package.cpath
    local lpeg = require"lpeg"
    package.cpath = pcp
  ```
  (Strictly speaking, this only needs to be done the first time lpeg is required, as it will be in the loaded table.)  
  
###Useful links:  
  Homepage of LPEG  
    http://www.inf.puc-rio.br/~roberto/lpeg/  
  About the re-module  
    http://www.inf.puc-rio.br/~roberto/lpeg/re.html  
  Mailing list post about building LPEG for Windows  
    http://lua-users.org/lists/lua-l/2007-05/msg00364.html  .
