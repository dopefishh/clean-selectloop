binaries:=Daytime Echo Wget

CLEAN_HOME?=/opt/clean

all: $(binaries)

prj: $(addsuffix .prj,$(binaries))

%: %.icl
	clm -IL Platform -IL TCPIP -IL Platform/Deprecated/StdLib -I ../libraries -h 200m -s 200m $@ -o $@

%.prj:
	cpm project $(basename $@) create
	cpm project $@ set -h 200m -s 200m
	cpm project $@ target iTasks
	cpm project $@ path add "$$PWD/../libraries"

clean:
	$(RM) -r $(binaries) Clean\ System\ Files *-sapl *-www

clobber: clean
	$(RM) *.prj
