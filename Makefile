# |
# o---------------------------------------------------------------------o
# |
# | MAD makefile
# |
# o---------------------------------------------------------------------o
# |
# | Methodical Accelerator Design
# |
# | Copyright (c) 2011+ CERN, mad@cern.ch
# |
# | For more information, see http://cern.ch/mad
# |
# o---------------------------------------------------------------------o
# |
# | $Id$
# |

#
# macros
#
eq    = $(if $(patsubst $1,,$2),,t)
_ := $(if $(call eq,$(SHOW),yes),,@)
E := $(if $(call eq,$(SHOW),yes),@ \#,@ echo)
RM   := rm -f
FIND := find

#
# rules
#
.PHONY: clean cleandir

clean:
	$E "** Cleaning local files"
	$_ $(RM) core
	$_ $(FIND) . -name '*~' -exec $(RM) {} \;

# end of makefile
