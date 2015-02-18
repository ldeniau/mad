###Installing:  
  Run the makefile contained in the lpeg-0.12 folder in this directory.  
  To make on macosx, run  
       make macosx [ LUADIR=/path/to/luajit/include ]
  and to make on linux, run  
       make linux  [ LUADIR=/path/to/luajit/include ]
  
###Reinstalling:
  Clean first the object and librarie files
  make clean

###Using re:  
  To use re, require it using the wrapper in this directory.
  ``` lua
    local re = require"lib.lpeg.re"
  ```  
  
###Using lpeg:  
  To use lpeg, use the lpeg-wrapper in the lib-folder.  
  ``` lua
    local lpeg = require"lib.lpeg"
  ```  
  
###Useful links:  
  Homepage of LPEG  
    http://www.inf.puc-rio.br/~roberto/lpeg/  
  About the re-module  
    http://www.inf.puc-rio.br/~roberto/lpeg/re.html  
  Mailing list post about building LPEG for Windows  
    http://lua-users.org/lists/lua-l/2007-05/msg00364.html  .
