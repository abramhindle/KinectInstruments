
glview2: glview2.c
	gcc -I../include glview2.c -o glview2 -lGL -lglut -lfreenect
difference: difference.c
	gcc -std=c99 -I../include difference.c -o difference -lGL -lglut -lfreenect

play:	glview2
	sudo ./glview2 | perl filter.pl | csound -dm6 -o devaudio -L stdin sine2.orc sine2.sco
playdiff:	difference
	./difference |  csound -dm6 -o devaudio -L stdin energy.orc energy.sco

playOsc:
	perl oscInstrument.pl | csound -dm6 -o devaudio -L stdin sine2.orc sine2.sco
playSkel:
	repos/OSCeleton/STDOUTeleton -w | perl stdouteletoninstrument.pl | csound -dm6 -o devaudio -L stdin sine2.orc sine2.sco


