#!/bin/bash
in_file="c_dabnew.f90"
out_file="c_dabnew.h"
mod_prefix="__dabnew_MOD_"
def_type="int *"

echo \
'// automatically generated parameter types
// make sure you change them where needed
//=========================================' > $out_file
cat $in_file |
    grep subroutine | grep -v end | grep -v ! |   # get all valid subroutine declarations
    sed -e "{ s/subroutine /void $mod_prefix/g;   # replace subroutine with void and add prefix
              s/(/($def_type/g;                   # add default type declaration for 1st parameter
              s/,/& $def_type/g;                  # add default type declaration for rest of parameters
              s/)/);/g;                           # add ending semi-colon
            }" >> $out_file                       # and output into file


