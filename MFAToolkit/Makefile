# check if kbase module
TOP_DIR = ../..
IN_KBASE=0
ifeq ($(wildcard TOP_DIR/tools/Makefile.common),'')
	include $(TOP_DIR)/tools/Makefile.common
	IN_KBASE=1
endif

CWD= $(shell pwd)
# CC
CC = g++
# LIBS
GLPKLIB = -lpthread -lglpk
LIBS = -lz ${GLPKLIB}
# INCS
MFATK_INC = -I${CWD}/include -L/kb/runtime/lib -I/kb/runtime/include
INCS = ${MFATK_INC}
# FLAGS
OFLAGS = -DLINUX -DNDEBUG -DIL_STD -DILOSTRICTPOD -DNOSAFEMEM -DNOBLOCKMEM -O3
FFLAGS = -fPIC -fexceptions
# CCFLAGS
CCFLAGS = ${INCS} ${OFLAGS} ${FFLAGS}
LDFLAGS = ${GLPKLIB}

CPLEXAPI = CPLEXapiEMPTY.cpp
SRCDIR=${CWD}/src

SRCFILES = ${SRCDIR}/driver.cpp ${SRCDIR}/MFAProblem.cpp ${SRCDIR}/${CPLEXAPI} ${SRCDIR}/SCIPapi.cpp ${SRCDIR}/GLPKapi.cpp ${SRCDIR}/LINDOapiEMPTY.cpp ${SRCDIR}/SolverInterface.cpp ${SRCDIR}/Species.cpp ${SRCDIR}/Data.cpp ${SRCDIR}/InterfaceFunctions.cpp ${SRCDIR}/Identity.cpp ${SRCDIR}/Reaction.cpp ${SRCDIR}/GlobalFunctions.cpp ${SRCDIR}/AtomCPP.cpp ${SRCDIR}/UtilityFunctions.cpp ${SRCDIR}/AtomType.cpp ${SRCDIR}/Gene.cpp ${SRCDIR}/GeneInterval.cpp ${SRCDIR}/stringDB.cpp
OBJFILES = $(SRCFILES:.cpp=.o)

mfatoolkit: $(OBJFILES)
	if [ ! -d bin ]; then mkdir bin; fi
	${CC} ${CCFLAGS} -o bin/mfatoolkit $(^) ${LDFLAGS}

%.o: %.cpp
	${CC} ${CCFLAGS} -c $<; mv *.o ${SRCDIR}

deploy-mfatoolkit:
	if [ ! -d ${TARGET}/etc/MFAToolkit ]; then mkdir -p ${TARGET}/etc/MFAToolkit; fi
	cp -r etc ${TARGET}
	cp bin/mfatoolkit ${TARGET}/bin
	if [ ${IN_KBASE} ]; then curl "http://bioseed.mcs.anl.gov/~devoid/scip" > ${TARGET}/bin/scip; chmod +x ${TARGET}/bin/scip; fi

deploy: mfatoolkit deploy-mfatoolkit

clean:
	rm -f ${SRCDIR}/*.o bin/mfatoolkit