VFILES=$(wildcard *.v)



engine : $(VFILES) Makefile
	iverilog -o engine $(VFILES)
	g++ -o display display.cpp

release: init clean engine prun


clean :
	rm -rf engine display

mrun : engine run

init :
	@cp input_clean.data input.data

run : 
	@echo "Running VeRiPG version 1.00.."
	@ ./engine > output.raw
	@egrep "^#" output.raw > output.out
	@cut output.out -c2- > output.final
	@cat output.final

trun : 
	@echo "Running VeRiPG version 1.00.."
	@ ./engine

prun :
	@echo ">> Running VeRiPG version 1.00 with display assist <<"
	@ ./engine > /dev/null 2>&1 &
	@ ./display

test : $(sort $(patsubst %.ok,%,$(wildcard test?.ok)))

test% : cpu mem%.hex
	@echo -n "test$* ... "
	@cp mem$*.hex mem.hex
	@cp test$*.ok test.ok
	@timeout 10 ./cpu > test.raw 2>&1
	-@egrep "^#" test.raw > test.out
	-@egrep "^@" test.raw > test.cycles
	@((diff -b test.out test.ok > /dev/null 2>&1) && echo "pass `cat test.cycles`") || (echo "fail" ; echo "\n\n----------- expected ----------"; cat test.ok ; echo "\n\n------------- found ----------"; cat test.out)
