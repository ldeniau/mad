
LIBDIR=./lib

OS_NAME=$(shell uname -s)
MH_NAME=$(shell uname -m)

ifeq (${OS_NAME}, Darwin)
LPEG_BUILD=macosx
else
LPEG_BUILD=linux
endif


all: ${LIBDIR}/lpeg.so

${LIBDIR}/lpeg.so:
	make -C ${LIBDIR}/lpeg-0.12 ${LPEG_BUILD}
	cp ${LIBDIR}/lpeg-0.12/lpeg.so ${LIBDIR}

clean:
	make -C ${LIBDIR}/lpeg-0.12 clean
	rm -f ${LIBDIR}/lpeg.so
